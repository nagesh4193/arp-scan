#!/usr/bin/perl
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
#
# $Id: get-oui.pl 7439 2006-06-01 11:18:42Z rsh $
#
# get-oui.pl -- Fetch the OUI file from the IEEE website
#
# Author: Roy Hills
# Date: 16 March 2006
#
# This script downloads the Ethernet OUI file from the IEEE website, and
# converts it to the format needed by arp-scan.
#
use warnings;
use strict;
use Getopt::Std;
use LWP::Simple;
#
my $default_url = 'http://standards.ieee.org/regauth/oui/oui.txt';
my $default_filename='oui.txt';
#
my $usage =
qq/Usage: get-oui.pl [options]
Fetch the Ethernet OUI file from the IEEE website, and save it in the format
used by arp-scan.

'options' is one or more of:
        -h Display this usage message.
        -f FILE Specify the output OUI file. Default=$default_filename
        -u URL Specify the URL to fetch the OUI data from.
           Default=$default_url
        -v Give verbose progress messages.
/;
my %opts;
my $verbose;
my $filename;
my $url;
my $lineno = 0;
#
# Process options
#
die "$usage\n" unless getopts('hf:v',\%opts);
if ($opts{h}) {
   print "$usage\n";
   exit(0);
}
if (defined $opts{f}) {
   $filename=$opts{f};
} else {
   $filename=$default_filename;
}
if (defined $opts{u}) {
   $url=$opts{u};
} else {
   $url=$default_url;
}
$verbose=$opts{v} ? 1 : 0;
#
# If the output filename already exists, rename it to filename.bak before
# we create the new output file.
#
if (-f $filename) {
   print "Renaming $filename to $filename.bak\n" if $verbose;
   rename $filename, "$filename.bak" || die "Could not rename $filename to $filename.bak\n";
}
#
# Fetch the content from the URL
#
print "Fetching OUI data from $url\n" if $verbose;
my $content = get $url;
die "Could not get OUI data from $url\n" unless defined $content;
my $content_length = length($content);
die "Zero-sized response from from $url\n" unless ($content_length > 0);
print "Fetched $content_length bytes\n" if $verbose;
#
# Open the output file for writing.
#
print "Opening output file $filename\n" if $verbose;
open OUTPUT, ">$filename" || die "Could not open $filename for writing";
#
# Write the header comments to the output file.
#
my ($sec,$min,$hour,$mday,$mon,$year,undef,undef,undef) = localtime();
$year += 1900;
$mon++;
my $date_string = sprintf("%04d-%02d-%02d %02d:%02d:%02d", $year, $mon, $mday,
                          $hour, $min, $sec);
my $header_comments =
qq/# oui.txt -- Ethernet vendor OUI file for arp-scan
#
# This file contains the Ethernet vendor OUIs for arp-scan.  These are used
# to determine the vendor for a give Ethernet interface given the MAC address.
#
# Each line of this file contains an OUI-vendor mapping in the form:
#
# <OUI><TAB><Vendor>
#
# Where <OUI> is the first three bytes of the MAC address in hex, and <Vendor>
# is the name of the vendor.
#
# Blank lines and lines beginning with "#" are ignored.
#
# This file was automatically generated by get-oui.pl at $date_string
# using data from $url
#
/;
print OUTPUT $header_comments;
#
# Parse the content received from the URL, and write the OUI entries to the
# output file.  Match lines that look like this:
# 00-00-00   (hex)                XEROX CORPORATION
# and write them to the output file looking like this:
# 000000	XEROX CORPORATION
#
while ($content =~ m/^(\w+)-(\w+)-(\w+)\s+\(hex\)\s+(.*)$/gm) {
   print OUTPUT "$1$2$3\t$4\n";
   $lineno++;
}
#
# All done.  Close the output file and print OUI entry count
#
close OUTPUT || die "Error closing output file\n";
print "$lineno OUI entries written to file $filename\n" if $verbose;
