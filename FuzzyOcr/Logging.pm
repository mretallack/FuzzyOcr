# <@LICENSE>
# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to you under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at:
# 
#     http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# </@LICENSE>

package FuzzyOcr::Logging;

use base 'Exporter';
our @EXPORT_OK = qw(debuglog errorlog infolog warnlog logfile);

use Mail::SpamAssassin::Logger qw(log_message would_log);
use FileHandle;
use Fcntl ':flock';
use POSIX qw(strftime);

sub logfile {
    my $conf = FuzzyOcr::Config::get_config();
    my $logtext = $_[0];
    my $time = strftime("%Y-%m-%d %H:%M:%S",localtime(time));
    $logtext =~ s/\n/\n                      /g;

    # Validate and untaint the focr_logfile
    my $untainted_file;
    if ($conf->{focr_logfile} =~ /^([\w\/\.\-]+)$/) {
        $untainted_file = $1;  # The untainted version of the filename
    } else {
        warn "Invalid filename in focr_logfile: $conf->{focr_logfile}";
        return;
    }

    unless ( open LOGFILE, ">>", $untainted_file ) {
       warn "Can't open $conf->{focr_logfile} for writing, check permissions";
       return;
    }
    flock( LOGFILE, LOCK_EX );
    seek( LOGFILE, 0, 2 );
    print LOGFILE "$time [$$] $logtext\n";
    close LOGFILE;
}

sub _not_debug {
    return $Mail::SpamAssassin::Logger::LOG_SA{level} != 3;
}
sub _log {
    my $conf = FuzzyOcr::Config::get_config();
    my $type  = $_[0];
    my @lines = split('\n',$_[1]);
    foreach (@lines) { log_message($type,"FuzzyOcr: $_"); }
}
    
sub errorlog {
    my $conf = FuzzyOcr::Config::get_config();
    _log("error",$_[0]) if $conf->{focr_log_stderr};
    if (defined $conf->{focr_logfile}) {
        logfile($_[0]);
    }
}

sub warnlog {
    my $conf = FuzzyOcr::Config::get_config();
    _log("warn",$_[0]) if $conf->{focr_log_stderr};
    if (defined $conf->{focr_logfile} and ($conf->{focr_verbose} >= 1)) {
        logfile($_[0]);
    }
}

sub infolog {
    my $conf = FuzzyOcr::Config::get_config();
    unless (_not_debug()) {
        _log("info",$_[0]) if $conf->{focr_log_stderr};
    }
    if (defined $conf->{focr_logfile} and ($conf->{focr_verbose} >= 2)) {
        logfile($_[0]);
    }
}

sub debuglog {
    my $conf = FuzzyOcr::Config::get_config();
    unless (_not_debug()) {
        _log("dbg",$_[0]) if $conf->{focr_log_stderr};
    }
    if (defined $conf->{focr_logfile} and ($conf->{focr_verbose} >= 3)) {
        logfile($_[0]);
    }
}

1;
