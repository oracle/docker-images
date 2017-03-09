#!/bin/powershell
# 
# Since: March, 2017
# Author: fjhorrillo@gmail.com
# Description: Build script for building Oracle Database Docker images.
# 
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
# 
# Copyright (c) 2017 Francisco Javier Horrillo Sancho. All rights reserved.
#

function usage() {
  Write-Host @"

Usage: buildDockerImage.ps1 -v [version] [-e | -s | -x] [-i]
Builds a Docker Image for Oracle Database.
  
Parameters:
   -v: version to build
       Choose one of: $(Get-ChildItem -Name -Directory)
   -e: creates image based on 'Enterprise Edition'
   -s: creates image based on 'Standard Edition 2'
   -x: creates image based on 'Express Edition'
   -i: ignores the MD5 checksums

* select one edition only: -e, -s, or -x

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
    md5sum -c Checksum.$EDITION
  } catch {
    echo "MD5 for required packages to build this image did not match!"
    echo "Make sure to download missing files in folder $VERSION."
    exit $?
  }
}
s
##############
#### MAIN ####
##############

if ( $args.Count -eq 0 ) {
  usage
}

# Parameters
$ENTERPRISE=0
$STANDARD=0
$EXPRESS=0
$VERSION="12.2.0.1"
$SKIPMD5=0
$DOCKEROPS=""

for($i=0; $i -lt $args.Count; $i++) {
  $optname=$args[$i].TrimStart("-")
  if ( ($i+1) -lt $args.Count -And -Not $args[$i+1].StartsWith("-") ) { $optarg=$args[++$i] }
  switch ($optname) {
    "h" {
      usage
    }
    "i" {
      $SKIPMD5=1
    }
    "e" {
      $ENTERPRISE=1
    }
    "s" {
      $STANDARD=1
    }
    "x" {
      $EXPRESS=1
    }
    "v" {
      $VERSION="$optarg"
    }
    default {
    # Should not occur
      echo "Unknown error while processing options inside buildDockerImage.ps1"
    }
  }
}

# Which Edition should be used?
if ( $(($ENTERPRISE + $STANDARD + $EXPRESS)) -gt 1 ) {
  usage
} elseif ( $ENTERPRISE -eq 1 ) {
  $EDITION="ee"
} elseif ( $STANDARD -eq 1 ) {
  if ( "$VERSION" -eq "12.2.0.1" ) {
     echo "Version 12.2.0.1 does not have Standard Edition available.";
     exit 1;
  } else {
     $EDITION="se2"
  }
} elseif (( $EXPRESS -eq 1 ) -And ( "$VERSION" -ne "11.2.0.2" )) {
  echo "Version $VERSION does not have Express Edition available.";
  exit 1;
} else {
  $EDITION="xe";
  $DOCKEROPS="--shm-size=1G";
}

# Oracle Database Image Name
$IMAGE_NAME="oracle/database:$VERSION-$EDITION"

# Go into version folder
cd $VERSION

if ( -Not $SKIPMD5 -eq 1 ) {
  checksumPackages
} else {
  echo "Ignored MD5 checksum."
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
  docker build --force-rm=true --no-cache=true $DOCKEROPS $PROXY_SETTINGS -t $IMAGE_NAME -f Dockerfile.$EDITION .
} catch {
  echo "There was an error building the image."
  exit 1
}
$BUILD_END=Get-Date
$BUILD_ELAPSED=(New-TimeSpan -Start $BUILD_START -End $BUILD_END).TotalSeconds

echo ""

if ( $? ) {
Write-Host @"
  Oracle Database Docker Image for '$EDITION' version $VERSION is ready to be extended: 
    
    --> $IMAGE_NAME

  Build completed in $BUILD_ELAPSED seconds.
  
"@

} else {
  echo "Oracle Database Docker Image was NOT successfully created. Check the output and correct any reported problems with the docker build operation."
}

