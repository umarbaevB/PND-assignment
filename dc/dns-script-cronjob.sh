#!/bin/bash -e

#add job to cron via:
#sudo crontab -e
#then add line:
#*/1 * * * * /path/dns-script.sh 2>&1 | logger -t dns-script



ip6=$(ip -o -6 addr list eth0 | awk '{print $4}' | cut -f1)
for ip in $ip6
do
    val=$(echo $ip | cut -d":" -f1)
    if [[ "$val" != "fe80" ]];
    then
        ip6=$ip
    fi
done


mask=$(echo $ip6 | cut -d/ -f2)
ip=$(echo $ip6 | cut -d/ -f1)
#echo $mask
#echo $ip

ip=$(sipcalc $ip | fgrep Expanded | cut -d '-' -f 2)
#echo $ip


prefix_len=0

IFS=':' read -ra part <<< "$ip"
for i in "${part[@]}"; do
    prefix+=$i
    prefix+=":"
    prefix_len=$((prefix_len + 16))
    if (($prefix_len >= $mask)); then
        break 
    fi
done

#echo $prefix


#note that this version uses pipes
#Sometimes it might be the case to "tee" command for that purpose
#for example: echo "string" | sudo tee "file" > "/dev/null"
#Add "-a" flag to "tee" to append to a file

if [ ! -f "/path/hosts.ipv6" ]; then
    touch "/path/hosts.ipv6"
fi

header=$(head -n 1 "/path/hosts.ipv6")
header=$(echo $header | cut -d# -f2)
header=$(echo $header | rev | cut -c 1- | rev )
#echo $header

prefix=$(echo $prefix | rev | cut -c 4- | rev )
#echo $prefix

if [[ "$header" != "$prefix" ]];
then
    touch -f "/path/dnsmasq-ipv6.more.conf"
    echo "listen-address=$ip" > "/path/dnsmasq-ipv6.more.conf"

    
    echo "# $prefix" > "/path/hosts.ipv6"
    while IFS= read -r line; do
        echo  "$prefix$line">> "/path/hosts.ipv6"
    done < "/path/EUI64-ips"
    /etc/init.d/dnsmasq restart
fi

