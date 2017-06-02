#!/usr/bin/env bash
# Description: check ALM status
# Author: Claudiu Tomescu
# E-mail: klau2005@gmail.com
# June 2016

alm_log=/var/lib/nagios/alm_log
xml_tmp=/var/lib/nagios/xml.tmp

/usr/bin/curl -s --header "content-type: text/soap+xml; charset=utf-8" --data-binary @/var/lib/nagios/heartbeat.xml http://127.0.0.1:2020/soap/almzsi.wsgi > "${xml_tmp}"

corba_status=$(awk 'BEGIN{FS="[<*>]"} {print $25}' "${xml_tmp}")
scp_status=$(awk 'BEGIN{FS="[<*>]"} {print $37}' "${xml_tmp}")

if [[ "${corba_status}" =~ "OK" ]] && [[ "${scp_status}" =~ "OK" ]]
then
        echo "ALM OK" > "${alm_log}"
        /usr/lib/nagios/plugins/check_log3.pl -l "${alm_log}" -p "ALM OK"  -c 1 -s /dev/null --negate
		exit_status=0
elif [[ ! "${corba_status}" =~ "OK" ]] && [[ "${scp_status}" =~ "OK" ]]
then
        echo "Corba KO" > "${alm_log}"
        /usr/lib/nagios/plugins/check_log3.pl -l "${alm_log}" -p "Corba KO"  -c 1 -s /dev/null
		exit_status=2
elif [[ ! "${scp_status}" =~ "OK" ]] && [[ "${corba_status}" =~ "OK" ]]
then
        echo "SCP80 KO" > "${alm_log}"
        /usr/lib/nagios/plugins/check_log3.pl -l "${alm_log}" -p "SCP80 KO"  -c 1 -s /dev/null
		exit_status=2
else
        echo "ALM KO" > "${alm_log}"
        /usr/lib/nagios/plugins/check_log3.pl -l "${alm_log}" -p "ALM KO"  -c 1 -s /dev/null
		exit_status=2
fi

rm "${xml_tmp}"

exit "${exit_status}"
