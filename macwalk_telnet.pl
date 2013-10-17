#!/usr/bin/perl

##################################################################
# macwalk_telnet.pl
# 
# Perl script to walk cisco switches to find the switch and port
# that a device is plugged into.
# 
# The script looks at the forwarding table to see what port and 
# switch it should try next finally running out at the last switch
# and port.  Great for L2 networks where you are trying to track
# down offending devices.
# 
# You will need to uncomment part of this code if you are using
# ssh and not telnet for access.
# 
##################################################################
# 
# Copyright (c) 2013,  Timothy Pozar
# All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met: 
# 
# 1. Redistributions of source code must retain the above copyright notice, this
#    list of conditions and the following disclaimer. 
# 2. Redistributions in binary form must reproduce the above copyright notice,
#    this list of conditions and the following disclaimer in the documentation
#    and/or other materials provided with the distribution. 
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
# FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
# COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
# INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
# BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
# LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
# ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.
# 
##################################################################

# use Net::SSH::Perl;
use File::Temp qw/ :POSIX /;
$dump_log = tmpnam();
print ("Dumplog is $dump_log\n");

$mac = "0000.5e00.0170";
$host = "hostnane_of_starting_switch";
$user = "vty_username";
$pass = "vty_password";
$cmd_show_cdp_nei = "show cdp nei ";
$cmd_show_mac_addr = "show mac address-table ";

if($ARGV[1] eq ""){
        print ("macwalk: roothost cisco_style_macaddress\n");
        print ("ie. $host $mac\n");
}

$host = $ARGV[0];
$mac = $ARGV[1];

print "Looking for $mac starting at host: $host\n";

while (1){
# my $ssh = Net::SSH::Perl->new($host);
# $ssh->login($user, $pass);

use Net::Telnet ();
$t = new Net::Telnet (Timeout => 10, Prompt => '/.*\>/', Dump_Log => $dump_log);
$t->open($host);
$t->login($user, $pass);

# Should be logged in now...

$cmd = $cmd_show_mac_addr . " | inc " . $mac;
@cmd_out = $t->cmd($cmd);

$line = matchline(@cmd_out,$mac);

# What will be returned will look like " 112 0000.5e00.0170 DYNAMIC Gi0/5"

($vlan, $foo2, $state, $interface) = split(' ',$line);

$cmd = $cmd_show_cdp_nei . $interface . " detail | inc Device";

# We are going to assume we only see one device per interface.  We need to grab the data from "Device ID:"
# 
# cs01-200p-sfo>sho cdp neighbors GigabitEthernet 0/24 detail 
# -------------------------
# Device ID: cs01-mainlibrary-sfo.sfwireless.org
# Entry address(es): 
#   IP address: 10.1.0.200
# Platform: cisco WS-C2960G-24TC-L,  Capabilities: Switch IGMP 
# Interface: GigabitEthernet0/24,  Port ID (outgoing port): GigabitEthernet0/23
# Holdtime : 154 sec
# [...]

@cmd_out = $t->cmd($cmd);

if (@cmd_out eq "") {
	print "end of the line - on $host $interface\n";
	exit;
}

$line = matchline(@cmd_out,"Device ID:");

($foo1, $nexthost) = split(/ID: /,$line);

if ($nexthost eq "" || $nexthost eq "Device ID") {
	print "end of the line - on $host $interface\n";
	exit;
}
print "Next Host to check: $nexthost\n";
$host = $nexthost;

$t->close();
unlink($dump_log);
}

sub matchline{
	$array = $_[0];
	$string = $_[1];
	@cmd_lines = split(/'\n'/,$array);
	foreach $line (@cmd_lines) {
		if($line =~ m/$string/g){
			$line =~ tr/ //s;                # compress any spaces.
			$line =~ s/^\s*(.*?)\s*$/$1/;    # strip any spaces from the front.
			return $line;
		}
	}
}

sub lastline{
	$array = $_[0];
	@cmd_lines = split('\n',$array);
	foreach $line (@cmd_lines) {
		$oldl = $l;
		$l = $line;
	}
	if($l =~ m/^ /){
		chop($oldl);
		$l = $oldl . '	' . $l;
	}
	return $l;
}

