#!/usr/local/bin/perl

##########################################################################
# netmask_table.pl - Quicky IPv4 subnet table generator.
# 
# $Id: netmask_table.pl,v 1.2 2009/10/23 21:16:25 pozar Exp $
# 
# Once upon a time, way back in the 1980s, I put an IPv4 netmask table
# together that took off and seems to be copied and published all
# over the net now.  (Just google "pozar" and "netmasks".) Back then
# I hand built this table.  A friend wanted an expanded table to any
# size netmask.  Instead of hand coding this again, I wrote this perl
# script...
#
# Just change the "$base_netmask_size" to what ever you want it to
# start out on and refernce as a the "base" netmask that is subnetting.
##########################################################################

$base_netmask_size = 24;

$ipv4_size = 32; 

# This is where we find out the details on the base subnet...
$all_bits_on = (2 ** $ipv4_size) - 1;
$base_subnet_size = $ipv4_size - $base_netmask_size;
$base_netmask = ($all_bits_on<<$base_subnet_size) & $all_bits_on;
$base_netmask_s = bin2octet($base_netmask);
$base_subnetmask = (~ $base_netmask) & $all_bits_on;
$base_subnetmask_s = bin2octet($base_subnetmask);

$netmask_size = $base_netmask_size;

while($netmask_size < ($ipv4_size-1)) {
	# This is where we find out the details on the various subnets...
	$subnet_size = $ipv4_size - $netmask_size;
	$netmask = ($all_bits_on<<$subnet_size) & $all_bits_on;
	$netmask_s = bin2octet($netmask);
	printf "Netmask %s /%i (%032b)\n",$netmask_s,$netmask_size,$netmask;

	$subnetmask = (~ $netmask) & $all_bits_on;
	$subnetmask_s = bin2octet($subnetmask);
	$num_subnets = ($base_subnetmask+1) / ($subnetmask+1);
	printf "There are %i subnets in a /%i\n",$num_subnets,$base_netmask_size;

	$n = 0;
	while ($n < $num_subnets){
		$low_ip = ($n / $num_subnets) * $base_subnetmask;
		if ($n > 0) {
			$low_ip++;
		}
		$low_ip_s = bin2octet($low_ip);
		$n++;
		$high_ip = ($n / $num_subnets) * $base_subnetmask;
		$high_ip_s = bin2octet($high_ip);
		printf "%s to %s\n",$low_ip_s,$high_ip_s;
	}
	printf "\n";
	$netmask_size++;
}

#
# Turn a 32-bit binary quantity into a dotted-notation string.
# Stolen from "ipmath" at http://meepzor.com/packages/ipmath/ipmath
# See: http://web.meepzor.com/packages/LICENSE.txt
sub bin2octet {
    local ($long) = @_;
    local (@octets) = ();
    local ($i);

    for ($i = 1; $i <= 4; $i++) {
	push(@octets, ($long & 0xFF));
	$long = $long >> 8;
    }
    @octets = reverse(@octets);
    return join(".", @octets);
}
