#!/bin/bash

min_req_python_ver=3.9

vercomp () {
    if [[ $1 == $2 ]]
    then
        return 0
    fi
    local IFS=.
    local i ver1=($1) ver2=($2)
    # fill empty fields in ver1 with zeros
    for ((i=${#ver1[@]}; i<${#ver2[@]}; i++))
    do
        ver1[i]=0
    done
    for ((i=0; i<${#ver1[@]}; i++))
    do
        if [[ -z ${ver2[i]} ]]
        then
            # fill empty fields in ver2 with zeros
            ver2[i]=0
        fi
        if ((10#${ver1[i]} > 10#${ver2[i]}))
        then
            return 1
        fi
        if ((10#${ver1[i]} < 10#${ver2[i]}))
        then
            return 2
        fi
    done
    return 0
}

get_newest_python_bin_name() {
    default_python_latest_bin_name="missing"
    verify_python_exists=$(compgen -c python3)
    if [ $? -eq 0 ]
    then
        get_python_three_minor=$(compgen -c python3 | sort -u | grep -P "^python3.\d+$" | grep -oP "\.\d+$" | cut -c2- | sort -n | tail -n 1)
        default_python_latest_bin_name="python3.${get_python_three_minor}"
        get_latest_python_full_path=$(which $default_python_latest_bin_name)
    fi
}
get_newest_python_bin_name

get_python_version=$(${default_python_latest_bin_name} -V)
if [ $? -ne 0 ]
then
    echo "ERROR! Unable to get python version"
    exit $?
fi

echo "Python Version: ${get_python_version}"
get_ver_only=$(echo ${get_python_version} | grep -oP [0-9]+\.[0-9]+ | head -1)
vercomp ${get_ver_only} ${min_req_python_ver}

# 0 : A = B
# 1 : A > B
# 2 : B > A
if [ $? -eq 2 ]
then
    echo "ERROR! Python must be at least version ${min_req_python_ver}"
    hint_install_python $OS $VER
    exit $?
fi

# get_latest_python_full_path
$get_latest_python_full_path /opt/graylog/log-replay/sendevents.py -F /opt/graylog/log-replay/config.yml -E mixed --overrides /opt/graylog/log-replay/overrides.yml --log /opt/graylog/log-replay/log.log
