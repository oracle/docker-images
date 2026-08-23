#
# oracle_home_analysis
#
# Copyright (c) 2019, 2023, Oracle and/or its affiliates.
#
#    NAME
#      oracle_home_analysis - Oracle Home Analysis
#
#    DESCRIPTION
#      Oracle Home Analysis
#
#    NOTES
#
#    MODIFIED   (MM/DD/YY)
#    nmuthukr    05/12/23 - Creation
#
#

# Include the required modules
use strict;
use warnings;

package OracleHomeAnalysis;

use parent 'applin';

# Constructor
sub new
{
    my ($class, $args) = @_;

    my $self = $class->SUPER::new($args);

    return $self;
}

sub initialize
{
    my ($self) = @_;

    my %config_spec = 
    (
        "segregate" => { "TYPE" => "STR" },
        "json-out" => { "TYPE" => "STR" },
        "html-out" => { "TYPE" => "STR" },
        "lite-build" => { "TYPE" => "STR" },
        "version" => { "TYPE" => "STR" }
    );

    $self->config()->initialize(\%config_spec);

    $self->_init_pattern();
}

sub _init_pattern
{
    my ($self) = @_;

    my ($version) = $self->config()->get("version");

    my $config_file = $self->env()->data_path() . "/" . $version . "_oracle_home_analysis.dat";
    #my $config_file = $self->env()->data_path() . "/" . "new_config.dat";

    my @cont = $self->file()->get_content($config_file);

    my ($line);

    my $others = "OTHERS:OTHERS:OTHERS:unknown:";

    for $line (@cont, $others)
    {
        next if ($line=~/^\#/);

        my ($pat, $cat, $scat, $class, $comment) = split(/\:/, $line);

        next if ((! defined $pat) || ($pat eq ""));

        $self->{"OH"}{"PAT"}{$pat}{"CAT"} = $cat;
        $self->{"OH"}{"PAT"}{$pat}{"SUBCAT"} = $scat;
        $self->{"OH"}{"PAT"}{$pat}{"CLASS"} = $class;
        $self->{"OH"}{"PAT"}{$pat}{"COMMENT"} = $comment;

        push(@{$self->{"OH"}{"PAT_LIST"}}, $pat); # for ordered reference
    }
}

sub _update_pattern
{
    my ($self, $fspath, $fpath, $pat, $lpath) = @_;

    my $class = $self->{"OH"}{"PAT"}{$pat}{"CLASS"};
    my $cat   = $self->{"OH"}{"PAT"}{$pat}{"CAT"};
    my $scat  = $self->{"OH"}{"PAT"}{$pat}{"SUBCAT"};

    my $fsize = 0;

    if (! defined $lpath)
    {
        $fsize = $self->file()->size($fpath);
    }

    $self->{"OH"}{"PAT"}{$pat}{"COUNT"}++;
    $self->{"OH"}{"PAT"}{$pat}{"SIZE"} += $fsize;

    $self->{"OH"}{"CLASS"}{$class}{"COUNT"}++;
    $self->{"OH"}{"CLASS"}{$class}{"SIZE"}+= $fsize;

    $self->{"OH"}{"CATEGORY"}{$cat}{$scat}{"COUNT"}++;
    $self->{"OH"}{"CATEGORY"}{$cat}{$scat}{"SIZE"}+= $fsize;

    my $icat = (defined $lpath) ? "LINK" : "FILE";

    $self->{"OH"}{$icat}{$fspath}{"CAT"} = $cat;
    $self->{"OH"}{$icat}{$fspath}{"SCAT"} = $scat;
    $self->{"OH"}{$icat}{$fspath}{"CLASS"} = $class;
    $self->{"OH"}{$icat}{$fspath}{"SIZE"} = $fsize;

    if (defined $lpath)
    {
        $self->{"OH"}{$icat}{$fspath}{"LINK"} = $lpath;
    }

    return if ($pat ne "OTHERS");

    print("$fsize : $class : $pat : $fspath : $fsize\n");
}

sub _copy_oracle_file
{
    my ($self, $src, $dst, $file) = @_;

    my ($dir, $lfile)=$file=~/^(.*?)(\/[^\/]+$)/;

    my $spath = $src . "/" . $file;
    my $ddir  = $dst . "/" . $dir;

    if (! -d $ddir)
    {
        $self->dir()->create_recursive($ddir);

        print("Creating directory $ddir\n");
    }

    $self->file()->copy_file($spath, $ddir);
}

sub _link_oracle_file
{
    my ($self, $dst, $file, $lpath) = @_;

    my ($dir, $lfile)=$file=~/^(.*?)(\/[^\/]+$)/;

    my $dpath = $dst . "/" . $file;
    my $ddir  = $dst . "/" . $dir;

    if (! -d $ddir)
    {
        $self->dir()->create_recursive($ddir);

        print("Creating directory $ddir\n");
    }

    print("Creating symlink : $dpath : $lpath\n");

    $self->file()->create_symlink($lpath, $dpath);
}

sub _segregate_oracle_home
{
    my ($self) = @_;

    my ($seg) = $self->config()->get("segregate");

    my ($lite_build) = $self->config()->get("lite-build");

    return if ((! defined $seg) || ($seg=~/^\s*$/) || (! defined $lite_build));

    print("SEGREGATE $seg\n");

    my $oh = $self->{"OH"}{"ORACLE_HOME"};

    my ($fspath);

    my $seg_base = $seg . "/base";

    my $seg_full = $seg . "/full";

    $self->dir()->create($seg_base);

    if ($lite_build eq "false")
    {
      $self->dir()->create($seg_full);
    }

    for $fspath (keys %{$self->{"OH"}{"FILE"}})
    {
        next if (($self->{"OH"}{"FILE"}{$fspath}{"CLASS"} ne "BASE") 
                 && ($lite_build eq "true"));
        if ($self->{"OH"}{"FILE"}{$fspath}{"CLASS"} eq "BASE")
        {
          $self->_copy_oracle_file($oh, $seg_base, $fspath);
        }
        else
        {
          $self->_copy_oracle_file($oh, $seg_full, $fspath);
        }
    }

    for $fspath (keys %{$self->{"OH"}{"LINK"}})
    {
        next if (($self->{"OH"}{"LINK"}{$fspath}{"CLASS"} ne "BASE") 
                 && ($lite_build eq "true"));

        my $lpath = $self->{"OH"}{"LINK"}{$fspath}{"LINK"};
        if ($self->{"OH"}{"LINK"}{$fspath}{"CLASS"} eq "BASE")
        {
          $self->_link_oracle_file($seg_base, $fspath, $lpath);
        }
        else
        {
          $self->_link_oracle_file($seg_full, $fspath, $lpath);
        }
    }
}

sub _find_pattern
{
    my ($self, $fpath) = @_;

    my $pat;

    for $pat (@{$self->{"OH"}{"PAT_LIST"}})
    {
        return $pat if ($fpath=~/^$pat$/);
    }

    return "OTHERS";
}

sub _scan_oracle_home_cbk
{
    my ($fpath, $self) = @_;

    my $lpath = undef;

    if (-l $fpath)
    {
        $lpath = readlink($fpath);
    }

    my $oh = $self->{"OH"}{"ORACLE_HOME"};

    my $fspath = $fpath;

    $fspath=~s/^$oh\///;

    my $pat = $self->_find_pattern($fspath);

    $self->_update_pattern($fspath, $fpath, $pat, $lpath);
}

sub _scan_oracle_home
{
    my ($self) = @_;

    my ($oh) = $self->config()->get("ARG");

    $self->log()->msg("Scanning Oracle Home ". $oh . "\n");

    $self->{"OH"}{"ORACLE_HOME"} = $oh;

    $self->dir()->scan($oh, \&_scan_oracle_home_cbk, $self);

    $self->_segregate_oracle_home();
}

sub _dump_out_files
{
    my ($self) = @_;

    my $th = \%{$self->{"OH"}};

    my $json_dump = $self->json()->json_generate($th);

    my $json_out = $self->config()->get("json-out");

    if (defined $json_out)
    {
        my ($ret, $msg) = $self->file()->write($json_out, $json_dump);

        if ($ret == 0)
        {
            print "Generated JSON O/P $json_out\n";
        }
        else 
        {
            print "JSON O/P $json_out failed : $msg\n";
        }
    }

    # if (defined $html_out)
    # {
    #     serialize_html($json_dump, $html_out);
    # }
}

sub run
{
    my ($self) = @_;

    $self->_scan_oracle_home();

    $self->_dump_out_files();
}

sub main
{
    my $oh = OracleHomeAnalysis->new();

    $oh->start();
}

main();
