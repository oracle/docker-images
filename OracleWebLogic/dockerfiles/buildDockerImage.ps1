#!/bin/powershell
# 
# Since: March, 2017
# Author: fjhorrillo@gmail.com
# Description: script to build a Docker image for WebLogic
# 
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
# 
# Copyright (c) 2017 Francisco Javier Horrillo Sancho. All rights reserved.
#

function usage() {
  Write-Host @"

Usage: buildDockerImage.ps1 -v [version] [-d | -g | -i] [-s] [-c]
Builds a Docker Image for Oracle WebLogic.
  
Parameters:
   -v: version to build. Required.
       Choose one of: $(Get-ChildItem -Name -Directory)
   -d: creates image based on 'developer' distribution
   -g: creates image based on 'generic' distribution
   -i: creates image based on 'infrastructure' distribution
   -c: enables Docker image layer cache during build
   -s: skips the MD5 check of packages

* select one distribution only: -d, -g, or -i

LICENSE CDDL 1.0 + GPL 2.0

Copyright (c) 2017 Francisco Javier Horrillo Sancho. All rights reserved.

"@
  exit 0
}

# Validate packages
function md5sum {
  param
  (
      [Parameter(Mandatory=$true, HelpMessage='The file containing the hash.')]
      [string]$c
  )
  $error = $false
  foreach ($line in (Get-Content $c)) {
    if ( -Not $line.StartsWith("#") -And $line -ne "" ) {
      $fields = $line -split '\s+'
      $hash = $fields[0].Trim().ToUpper()
      $filename = $fields[1].Trim()
      if($filename.StartsWith("*")){
        $filename = $filename.Substring(1).Trim()
      }

      try {
        $computedHash = (Get-FileHash -Algorithm MD5 $filename -ErrorAction SilentlyContinue).Hash.ToUpper()
        if($hash.Equals($computedHash)){
          Write-Host $filename, ": Passed"
        }else{
          Write-Host $filename, ": Not Passed"
          Write-Host "Read from file: ", $hash
          Write-Host "Computed:       ", $computedHash
          $error = $true
        }
      } catch {
        Write-Host $filename, ": Not Found"
        $error = $true
      }
    }
  }
  if ($error) { Throw }  
}

function checksumPackages() {
  try {
    echo "Checking if required packages are present and valid..."
    md5sum -c Checksum.$DISTRIBUTION
  } catch {
    echo "MD5 for required packages to build this image did not match!"
    echo "Make sure to download missing files in folder $VERSION."
    exit $?
  }
}

##############
#### MAIN ####
##############

if ( $args.Count -eq 0 ) {
  usage
}

# Parameters
$DEVELOPER=0
$GENERIC=0
$INFRASTRUCTURE=0
$VERSION="12.2.1"
$SKIPMD5=0
$NOCACHE=$true

for($i=0; $i -lt $args.Count; $i++) {
  $optname=$args[$i].TrimStart("-")
  if ( ($i+1) -lt $args.Count -And -Not $args[$i+1].StartsWith("-") ) { $optarg=$args[++$i] }
  switch ($optname) {
    "h" {
      usage
    }
    "s" {
      $SKIPMD5=1
    }
    "d" {
      $DEVELOPER=1
    }
    "g" {
      $GENERIC=1
    }
    "i" {
      $INFRASTRUCTURE=1
    }
    "v" {
      $VERSION="$optarg"
    }
    "c" {
      $NOCACHE=$false
    }
    default {
    # Should not occur
      echo "Unknown error while processing options inside buildDockerImage.ps1"
    }
  }
}

# Which distribution to use?
if ( $(($DEVELOPER + $GENERIC + $INFRASTRUCTURE)) -gt 1 ) {
  usage
} elseif ( $DEVELOPER -eq 1 ) {
  $DISTRIBUTION="developer"
} elseif ( $GENERIC -eq 1 ) {
  $DISTRIBUTION="generic"
} elseif ( ($INFRASTRUCTURE -eq 1) -And ("$VERSION" -eq "12.1.3") ) {
  echo "Version 12.1.3 does not have infrastructure distribution available."
  exit 1
} else {
  $DISTRIBUTION="infrastructure"
}

# WebLogic Image Name
$IMAGE_NAME="oracle/weblogic:$VERSION-$DISTRIBUTION"

# Go into version folder
cd $VERSION

if ( -Not $SKIPMD5 -eq 1 ) {
  checksumPackages
} else {
  echo "Skipped MD5 checksum."
}

echo "=========================="
echo "DOCKER version:"
docker version
echo "=========================="

# Proxy settings
$PROXY_SETTINGS=""
if ( "${http_proxy}" -ne "" ) {
  $PROXY_SETTINGS="$PROXY_SETTINGS --build-arg http_proxy=${http_proxy}"
}

if ( "${https_proxy}" -ne "" ) {
  $PROXY_SETTINGS="$PROXY_SETTINGS --build-arg https_proxy=${https_proxy}"
}

if ( "${ftp_proxy}" -ne "" ) {
  $PROXY_SETTINGS="$PROXY_SETTINGS --build-arg ftp_proxy=${ftp_proxy}"
}

if ( "${no_proxy}" -ne "" ) {
  $PROXY_SETTINGS="$PROXY_SETTINGS --build-arg no_proxy=${no_proxy}"
}

if ( "$PROXY_SETTINGS" -ne "" ) {
  echo "Proxy settings were found and will be used during the build."
}

# ################## #
# BUILDING THE IMAGE #
# ################## #
echo "Building image '$IMAGE_NAME' ..."

# BUILD THE IMAGE (replace all environment variables)
$BUILD_START=Get-Date
try {
  docker build --force-rm=$NOCACHE --no-cache=$NOCACHE $DOCKEROPS $PROXY_SETTINGS -t $IMAGE_NAME -f Dockerfile.$DISTRIBUTION .
} catch {
  echo "There was an error building the image."
  exit 1
}
$BUILD_END=Get-Date
$BUILD_ELAPSED=(New-TimeSpan -Start $BUILD_START -End $BUILD_END).TotalSeconds

echo ""

if ( $? ) {
Write-Host @"
  WebLogic Docker Image for '$DISTRIBUTION' version $VERSION is ready to be extended: 
    
    --> $IMAGE_NAME

  Build completed in $BUILD_ELAPSED seconds.
  
"@

} else {
  echo "WebLogic Docker Image was NOT successfully created. Check the output and correct any reported problems with the docker build operation."
}

