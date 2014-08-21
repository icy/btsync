#!/usr/bin/env perl

# Purpose: print a sample report
# Author : Anh K. Huynh
# License: MIT
# Date   : 2014 Aug 21st
# Usage  : ./api.sh folder_get | ./report.pl

use JSON;

my $jS0n = do { local $/; <STDIN> };
my $json = decode_json( $jS0n );
my $folders = $json->{"folders"};
for ( keys @{$folders} ) {
  my $d = $folders->[$_];
  printf "key: %s name: %s\n", $d->{"secret"}, $d->{"name"};
}
