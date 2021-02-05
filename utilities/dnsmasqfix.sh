#!/bin/sh




updatednsmasq() {


cat <<'LLL' > /tmp/distfeeds.conf
src/gz openwrt_base https://downloads.openwrt.org/snapshots/packages/aarch64_cortex-a72/base
LLL
cat <<'LLL' > /tmp/customfeeds.conf
#
LLL

mount -o bind /tmp/distfeeds.conf /etc/opkg/distfeeds.conf
mount -o bind /tmp/customfeeds.conf /etc/opkg/customfeeds.conf



#MASQDEBUG=1
#MASQvariant=

if [ -n "$MASQDEBUG" ] && [ -z "$MASQvariant" ]; then
	MASQmsg="$MASQmsg dnsmasq is not installed"
	NOVARIANT=1
elif [ -n "$MASQDEBUG" ]; then
	#echo "Checking for newer version for $MASQvariant $MASQver $onsysVERSION"
	LOGMSG "Checking for newer version for $MASQvariant $MASQver $onsysVERSION"
fi



#if [ -z "$MASQvariant" ]; then MASQmsg="$MASQmsg dnsmasq is not installed"


if [ -n "$MASQDEBUG" ]; then #if [ -n "$MASQDEBUG" ] && [ ! -z "$MASQvariant" ]; then
	#echo "opkg update 1>/dev/null 2>/dev/null" #opkg update
	if ! opkg update 1>/dev/null 2>/dev/null; then
		MASQmsg="$MASQmsg opkgupdatefailed"
		OPKGUPDfail=1
	fi
else #elif [ ! -z "$MASQvariant" ]; then
	if ! opkg update 1>/dev/null 2>/dev/null; then
		MASQmsg="$MASQmsg opkgupdatefailed"
		OPKGUPDfail=1
	fi
fi




if [ -z "$OPKGUPDfail" ] && [ -z "$NOVARIANT" ] && opkg list-upgradable | \
	cut -d' ' -f1 | grep -q "^$MASQvariant$"; then #@@@propervariant


	VERFOUND=$(opkg list-upgradable | grep 'dnsmasq')

	[ -n "$MASQDEBUG" ] && echo "VERFOUND: $(opkg list-upgradable | grep 'dnsmasq')"

	if [ ! -z "$(pidof dnsmasq)" ]; then MASQRUNNING=1 ; fi


	[ -n "$MASQDEBUG" ] && echo "opkg upgrade $MASQvariant"

	if [ -n "$MASQDEBUG" ]; then
		if opkg upgrade $MASQvariant; then
			MASQUPDATED=1
		else
			MASQmsg="${MASQmsg} opkgupgradecmdfailed"
		fi
	else
		if opkg upgrade $MASQvariant 1>/dev/null 2>/dev/null; then
			MASQUPDATED=1
		else
			MASQmsg="${MASQmsg} opkgupgradecmdfailed"
		fi
	fi


else
	[ -n "$MASQDEBUG" ] && opkg list-upgradable
	MASQmsg="${MASQmsg} no-update-${MASQvariant}-${MASQver}"
fi


while [ ! -z "$(mount | grep feeds | cut -d' ' -f3)" ]; do
	umount $(mount | grep feeds | cut -d' ' -f3 | head -n1) 1>/dev/null 2>/dev/null
done; rm /tmp/distfeeds.conf 2>/dev/null; rm /tmp/customfeeds.conf 2>/dev/null



if [ ! -z "$MASQUPDATED" ]; then
	#logger -t vulfix "dnsmasq patched: $MASQvariant $MASQmsg"
	LOGMSG "dnsmasq patched: $MASQvariant $MASQmsg $VERFOUND"
	if [ ! -z "$MASQRUNNING" ]; then
		#[ -n "$MASQDEBUG" ] && echo "/etc/init.d/dnsmasq restart"
		LOGMSG "dnsmasq restart"
		/etc/init.d/dnsmasq stop 1>/dev/null 2>/dev/null
		sleep 3
		/etc/init.d/dnsmasq start 1>/dev/null 2>/dev/null
	fi
	return 0
fi


#logger -t vulfix "dnsmasq patch failed: $MASQvariant $MASQmsg"
LOGMSG "dnsmasq patch failed: $MASQvariant $MASQmsg"
return 1

}





#MASQDEBUG=1

LOGMSG() {
	logger -t vulfix "${1}"
	echo "${1}"
}
















MASQver=$(opkg list-installed | grep dnsmasq | cut -d' ' -f3)
MASQvariant=$(opkg list-installed | sed -n '/dnsmasq/ s/\([a-z]*\) - .*/\1/p')

onsysVERSION=$(cat /etc/custom/buildinfo.txt | grep '^localversion' | cut -d'=' -f2 | sed 's/"//g' | sed "s/'//g")













#meh... bump to 2.5 will do it
############################# set all 2.3 on then turn recent off for now
#case "$onesysVERSION" in
#    *"2.3."*)
#        NEEDSUPDATE=1
#    ;;
#esac
##case "$onesysVERSION" in
##    *"2.3.9"*) #meh will match 9 - 90
##        NEEDSUPDATE=
##    ;;
##esac
###############################################################if NEEDSUPDATE tba
#rpi-4_snapshot_2.3.656-15_r15323_extra  rpi-4_snapshot_2.3.656-16_r15323_std  rpi-4_snapshot_2.3.770-13_r15549_extra



















#if [ ! -f /root/.dnsmasq.patched ]; then


if [ -z "$MASQver" ] || [ -z "$MASQvariant" ]; then #DBG MASQvariant=
	LOGMSG "masq update due to known vulnerabilities: $MASQvariant $MASQver [not-installed]"
else


case "$onsysVERSION" in #"2.3"*|"2.5"*)
	"2.5"*|"2.7"*)
		LOGMSG "new build no check needed: $MASQvariant $MASQmsg $MASQver"
        touch /root/.dnsmasq.patched
        ;; #next build should not have issue
	"2.3"*)

		case "$MASQver" in #"2.82"*) : ;; #"2.83"*) : ;;
			"2.82"*|"2.83"*) #"2.82"*)

			rm /root/.dnsmasq.patched 2>/dev/null
			if [ ! -f /root/.dnsmasq.patched ]; then
				updatednsmasq
			fi
			;;
			"2.83"*)
				#logger -t vulfix "masq version is ok: $MASQvariant $MASQmsg $MASQver"
				LOGMSG "masq version is ok: $MASQvariant $MASQmsg $MASQver"
				touch /root/.dnsmasq.patched
			;;
			esac
		;;

	*)
		#logger -t vulfix "your build is ancient update due to known vulnerabilities: $MASQvariant $MASQmsg"
		LOGMSG "your build is ancient update due to known vulnerabilities: $MASQvariant $MASQmsg $MASQver"
	;;
esac




fi #end -z ver or variant



#fi #end ! -f patched







#curl -sSL https://raw.githubusercontent.com/wulfy23/rpi4/master/utilities/dnsmasqfix.sh > /tmp/dnsmasqfix.sh; chmod +x /tmp/dnsmasqfix.sh; /tmp/dnsmasqfix.sh








