#!/bin/sh

# File:		ping_fg_mp_servers.sh
# Author:	Megaf - https://github.com/Megaf/
# Bugs:		https://github.com/Megaf/ping_fg_mp_servers.sh/issues
# GitHub:	https://github.com/Megaf/ping_fg_mp_servers.sh
# License:	GNU General Public License v3.0
#
# This is a simple script to ping all FlightGear mpservers that are tracked by https://fgtracker.ml/modules/fgtracker/ or OPRF.
# Edit servers.list file to change the server you want to test.

# Temp file used to compare ping times.
tmpfile="/tmp/mp_ping_results.txt"

# Server list
list="servers.list"

# Delete temp file from previous run.
rm -f "$tmpfile"

# Number of pings per server.
nping="5"

# Time between pings, in seconds.
pingt="0.5"

# IP version to use, 4 or 6.
ipv="4"

# Package size to send in the pings, in bytes.
pkgsz="1508"

# Raw ping output per server.
working="/tmp/ping.working"

# Spinner animation function.
anim()
{
	n=0
	sp='/-\|'
	while [ "$n" -lt "$nping" ]
	do
		printf '\b%.1s' "$sp"
		sp=${sp#?}${sp%???}
		sleep "0.2"
		n=$(grep from "$working" | wc -l)
	done
}

# ping function.
ping_()
{
	echo "0" > $working
	echo "Pinging server $server. Please wait."
	ping -w 10 -W 5 -n -s "$pkgsz" -"$ipv" "$server" -i "$pingt" -c "$nping" > $working & anim
	output=$(tail -n 1 $working)
	printf "\r"
	echo "Done."
	echo ""
	
	avg=$(echo $output | awk -O -F '/' 'END {print $5}')
	dif=$(echo $output | awk -O -F '/' 'END {print $7}')
	echo "Average ping is $avg ms."
	echo "Jitter is $dif"
	echo "---------"
	echo ""
	echo "$server $avg $dif" >> $tmpfile
}

# Show result function.
prnt_rslt()
{
	smlset=$(sort -k 2 -n -r "$tmpfile" | tail -n 1)
	echo "$smlset" | awk -O -F ' ' 'END {print "The server with the smallest ping is: " $1}'
	echo "$smlset" | awk -O -F ' ' 'END {print "It has a ping of: " $2 " ms."}'
	echo ""
	smlset=$(sort -k 3 -n -r "$tmpfile" | tail -n 1)
	echo "$smlset" | awk -O -F ' ' 'END {print "The server with the smallest jitter is: " $1}'
	echo "$smlset" | awk -O -F ' ' 'END {print "It has jitter of: " $3 " ms."}'
	echo ""
	echo "Results saved to $tmpfile."
}

# Stuff function.
do_stuff()
{
	echo "Begining to ping the main FG MP servers tracked by fgtracker(https://fgtracker.ml/) or OPRF(http://opredflag.com/)"
	while IFS= read -r line;
	do
		server="$line"
		ping_
	done < "$list"
}

do_stuff # Does stuff.
prnt_rslt # Print the best server.

exit 0
