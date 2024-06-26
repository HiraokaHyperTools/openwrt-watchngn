#!/bin/sh
#
# Copyright (C) 2010 segal.di.ubi.pt
# Copyright (C) 2020 nbembedded.com
#
# This is free software, licensed under the GNU General Public License v2.
#

get_ping_size() {
	ps=$1
	case "$ps" in
	small)
		ps="1"
		;;
	windows)
		ps="32"
		;;
	standard)
		ps="56"
		;;
	big)
		ps="248"
		;;
	huge)
		ps="1492"
		;;
	jumbo)
		ps="9000"
		;;
	*)
		echo "Error: invalid ping_size. ping_size should be either: small, windows, standard, big, huge or jumbo"
		echo "Cooresponding ping packet sizes (bytes): small=1, windows=32, standard=56, big=248, huge=1492, jumbo=9000"
		;;
	esac
	echo $ps
}

reboot_now() {
	reboot &

	[ "$1" -ge 1 ] && {
		sleep "$1"
		echo 1 > /proc/sys/kernel/sysrq
		echo b > /proc/sysrq-trigger # Will immediately reboot the system without syncing or unmounting your disks.
	}
}

watchngn_restart_network_iface() {
	logger -p daemon.info -t "watchngn[$$]" "Restarting network interface: \"$1\"."
	ip link set "$1" down
	ip link set "$1" up
}

watchngn_restart_all_network() {
	logger -p daemon.info -t "watchngn[$$]" "Restarting networking now by running: /etc/init.d/network restart"
	/etc/init.d/network restart
}

watchngn_odhcp6c_renew() {
	logger -p daemon.info -t "watchngn[$$]" "Triggering odhcp6c to renew"
	kill -SIGUSR2 `pidof odhcp6c`
}

watchngn_monitor_network() {
	failure_period="$1"
	ping_hosts="$2"
	ping_frequency_interval="$3"
	ping_size="$4"
	iface="$5"

	time_now="$(cat /proc/uptime)"
	time_now="${time_now%%.*}"

	[ "$time_now" -lt "$failure_period" ] && sleep "$((failure_period - time_now))"

	time_now="$(cat /proc/uptime)"
	time_now="${time_now%%.*}"
	time_lastcheck="$time_now"
	time_lastcheck_withinternet="$time_now"

	ping_size="$(get_ping_size "$ping_size")"

	logger -p daemon.info -t "watchngn[$$]" "Start watching"

	while true; do
		# account for the time ping took to return. With a ping time of 5s, ping might take more than that, so it is important to avoid even more delay.
		time_now="$(cat /proc/uptime)"
		time_now="${time_now%%.*}"
		time_diff="$((time_now - time_lastcheck))"

		[ "$time_diff" -lt "$ping_frequency_interval" ] && sleep "$((ping_frequency_interval - time_diff))"

		time_now="$(cat /proc/uptime)"
		time_now="${time_now%%.*}"
		time_lastcheck="$time_now"

		for host in $ping_hosts; do
			if [ "$iface" != "" ]; then
				ping_result="$(
					ping -I "$iface" -s "$ping_size" -c 1 "$host" &> /dev/null
					echo $?
				)"
			else
				ping_result="$(
					ping -s "$ping_size" -c 1 "$host" &> /dev/null
					echo $?
				)"
			fi

			if [ "$ping_result" -eq 0 ]; then
				time_lastcheck_withinternet="$time_now"
			else
				if [ "$iface" != "" ]; then
					logger -p daemon.info -t "watchngn[$$]" "Could not reach $host via \"$iface\" for \"$((time_now - time_lastcheck_withinternet))\" seconds. Restarting \"$iface\" after reaching \"$failure_period\" seconds"
				else
					logger -p daemon.info -t "watchngn[$$]" "Could not reach $host for \"$((time_now - time_lastcheck_withinternet))\" seconds. Restarting networking after reaching \"$failure_period\" seconds"
				fi
			fi
		done

		[ "$((time_now - time_lastcheck_withinternet))" -ge "$failure_period" ] && {
			if [ "$iface" != "" ]; then
				watchngn_odhcp6c_renew "$iface"
			else
				watchngn_odhcp6c_renew
			fi

			logger -p daemon.info -t "watchngn[$$]" "Entering restart sleep"
			sleep 300
			logger -p daemon.info -t "watchngn[$$]" "Leaving restart sleep"

			/etc/init.d/watchngn start

			# Restart sleep should not be considered as downtime.
			time_now="$(cat /proc/uptime)"
			time_now="${time_now%%.*}"

			# Restart timer cycle.
			time_lastcheck_withinternet="$time_now"
		}

	done
}

mode="$1"

case "$mode" in
renew)
	watchngn_monitor_network "$2" "$3" "$4" "$5" "$6"
	;;
*)
	echo "Error: invalid mode selected: $mode"
	;;
esac
