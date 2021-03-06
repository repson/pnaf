#!/usr/bin/perl -I..

#########################################################################################
# Copyright (c) 2007 Jason Brvenik.
# A Perl module to make it easy to work with snort unified files.
# http://www.snort.org
# 
# Basic barnyard like functionality
#########################################################################################
# 
#
# The intellectual property rights in this program are owned by 
# Jason Brvenik.  This program may be copied, distributed and/or 
# modified only in accordance with the terms and conditions of 
# Version 2 of the GNU General Public License (dated June 1991).  By 
# accessing, using, modifying and/or copying this program, you are 
# agreeing to be bound by the terms and conditions of Version 2 of 
# the GNU General Public License (dated June 1991).
#
# This program is distributed in the hope that it will be useful, but 
# WITHOUT ANY WARRANTY; without even the implied warranty of 
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  
# See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License 
# along with this program; if not, write to the 
# Free Software Foundation, Inc., 51 Franklin St, Fifth Floor, 
# Boston, MA  02110-1301  USA 
# 
# 
#
#########################################################################################

use SnortUnified qw(:ALL);
use SnortUnified::Database qw(:ALL);
use SnortUnified::MetaData(qw(:ALL));
use Sys::Hostname;

print License . "\n";

$file = shift;
$UF_Data = {};
$record = {};

$sids = get_snort_sids("/Users/jbrvenik/src/test/unified/sid-msg.map",
                       "/Users/jbrvenik/src/test/unified/gen-msg.map");
$class = get_snort_classifications("/Users/jbrvenik/src/test/unified/classification.config");

# If you want to see them
# print_snort_sids($sids);

# If you want to see them
# print_snort_classifications($class);

setSnortConnParam('user', 'root');
setSnortConnParam('password', '');
setSnortConnParam('interface', 'eth1');
setSnortConnParam('database', 'snorttest');
setSnortConnParam('hostname', Sys::Hostname::hostname());
setSnortConnParam('filter', '');

die unless getSnortDBHandle();

my $sensor_id = getSnortSensorID();
my $uf_file = undef;
my $old_uf_file = undef;

# print("Sensor ID is " . $sensor_id . "\n");

printSnortConnParams();
printSnortSigIdMap();


$uf_file = get_latest_file($file) || die "no files to get";
die unless $UF_Data = openSnortUnified($uf_file);

# while ( $record = readSnortUnifiedRecord() ) {
while (1) {
  $old_uf_file = $uf_file;
  $uf_file = get_latest_file() || die "no files to get";
  
  if ( $old_uf_file ne $uf_file ) {
    closeSnortUnified();
    $UF_Data = openSnortUnified($uf_file) || die "cannot open $uf_file";
  }

  read_records();
}

sub read_records() {
  while ( $record = readSnortUnifiedRecord() ) {
    if ( $UF_Data->{'TYPE'} eq 'LOG' ) {
        print_log($record,$sids,$class);
	insertSnortLog($record,$sids,$class);
    } else {
        print_alert($record,$sids,$class);
	insertSnortAlert($record,$sids,$class);
    }
  }
  return 0;
}

# clean up
closeSnortUnified();
closeSnortDBHandle();


sub get_latest_file($) {
  my $filemask = shift;
  my @ls = <$filemask*>;
  my $len = @ls;
  my $uf_file = "";

  if ($len) {
    # Get the most recent file
    my @tmparray = sort{$b cmp $a}(@ls);
    $uf_file = shift(@tmparray);
  } else {
    $uf_file = undef;
  }
  return $uf_file;
}

