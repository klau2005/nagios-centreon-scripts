#!/usr/bin/env bash
# Author: Claudiu Tomescu
# E-mail: klau2005@gmail.com

#----------- Variables --------------#

today=$(date +%m%d)
log_file="/home/simphobe/exe/sys/alm_archiver/arc/rtm/${today}/rtm"

if [[ ! -f "/tmp/rtm_seek_file" ]]
then
    printf "%s\n%s" "0" "${today}" > "/tmp/rtm_seek_file" && seek_file="/tmp/rtm_seek_file"
else
    seek_file="/tmp/rtm_seek_file"
fi

all_lines=$(awk "END {print NR}" "${log_file}")
last_line=$(/usr/bin/awk 'NR==1 {print $0}' "${seek_file}")
day_last=$(/usr/bin/awk 'NR==2 {print $0}' "${seek_file}")

#---------- Functions ---------------#

function rtm {
    echo ${all_lines} > "${seek_file}"
    echo "${today}" >> "${seek_file}"
    /bin/sed -n ''$(($1+1))',$p' "${log_file}" >> "${seek_file}"
    total_ops=$(grep -c "Creating session" "${seek_file}")
    fail_ops=$(grep -c "Operation failed (FAILED)" "${seek_file}")
    success_ops=$(grep -c "Operation finished" "${seek_file}")
}

#----------- Script body ------------#

if [[ "${today}" -eq "${day_last}" ]]
then
    rtm "${last_line}"
else
    rtm "0"
fi

if [[ 10#$total_ops -gt 15 ]]
then
    if [[ $((10#$fail_ops * 100 / 10#$total_ops)) -gt 80 ]]
    then
        echo "RTM FAIL" >> "${seek_file}"
        /usr/lib/nagios/plugins/check_log3.pl -l "${seek_file}" -p "RTM FAIL"  -c 1 -s /dev/null
        exit_stat=2
    else
        echo "RTM OK" >> "${seek_file}"
        /usr/lib/nagios/plugins/check_log3.pl -l "${seek_file}" -p "RTM FAIL"  -c 1 -s /dev/null
        exit_stat=0
    fi
else
    echo "RTM OK" >> "${seek_file}"
    /usr/lib/nagios/plugins/check_log3.pl -l "${seek_file}" -p "RTM FAIL"  -c 1 -s /dev/null
    exit_stat=0
fi

exit "${exit_stat}"
