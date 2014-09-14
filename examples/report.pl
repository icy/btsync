#!/usr/bin/env perl

# Purpose: Print a sample report
# Author : Anh K. Huynh
# License: MIT
# Date   : 2014 Aug 21st
# Usage  : ./api.sh folder/get | ./report.pl

use JSON;

my $jS0n = do { local $/; <STDIN> };
my $json = decode_json( $jS0n );
my $folders = $json->{"folders"};

for ( keys @{$folders} ) {
  my $d = $folders->[$_];
  printf "key: %s name: %s size: %s\n",
    $d->{"secret"}, $d->{"name"}, get_filesize_str($d->{"size"});
}

# http://www.use-strict.de/perl-file-size-in-a-human-readable-format.html
sub get_filesize_str
{
    my $size = shift;

    if ($size > 1099511627776)  #   TiB: 1024 GiB
    {
        return sprintf("%.2fTiB", $size / 1099511627776);
    }
    elsif ($size > 1073741824)  #   GiB: 1024 MiB
    {
        return sprintf("%.2fGiB", $size / 1073741824);
    }
    elsif ($size > 1048576)     #   MiB: 1024 KiB
    {
        return sprintf("%.2fMiB", $size / 1048576);
    }
    elsif ($size > 1024)        #   KiB: 1024 B
    {
        return sprintf("%.2fKiB", $size / 1024);
    }
    else                          #   bytes
    {
        return "${size}B" . ($size <= 1 ? "" : "s");
    }
}
