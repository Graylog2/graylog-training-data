#!/bin/bash
cd "$(dirname "$0")"

# Install python 3.10
# sudo apt install software-properties-common -y
# sudo add-apt-repository ppa:deadsnakes/ppa
# sudo apt install python3.10
# set as default
# sudo update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.9 1
# install pip
# curl -sS https://bootstrap.pypa.io/get-pip.py | python3.10

min_req_python_ver=3.9

if [ -f /etc/os-release ]; then
    # freedesktop.org and systemd
    . /etc/os-release
    OS=$NAME
    VER=$VERSION_ID
elif type lsb_release >/dev/null 2>&1; then
    # linuxbase.org
    OS=$(lsb_release -si)
    VER=$(lsb_release -sr)
elif [ -f /etc/lsb-release ]; then
    # For some versions of Debian/Ubuntu without lsb_release command
    . /etc/lsb-release
    OS=$DISTRIB_ID
    VER=$DISTRIB_RELEASE
elif [ -f /etc/debian_version ]; then
    # Older Debian/Ubuntu/etc.
    OS=Debian
    VER=$(cat /etc/debian_version)
elif [ -f /etc/SuSe-release ]; then
    # Older SuSE/etc.
    ...
elif [ -f /etc/redhat-release ]; then
    # Older Red Hat, CentOS, etc.
    ...
else
    # Fall back to uname, e.g. "Linux <version>", also works for BSD, etc.
    OS=$(uname -s)
    VER=$(uname -r)
fi

root_check() {
    get_curusr=$(whoami)
    if [ $get_curusr == "root" ]
    then
        ok="okhere"
    else
        echo "ERROR! Please run as root."
        echo "Try: 'sudo su' to elevate and then run install script again."
        exit 1
    fi
}
root_check

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

init_os_verify_check() {
    os_is_compat=0

    if [ $1 == "Ubuntu" ]
    then
        if [ $2 == "20.04" ]
        then
            os_is_compat=1
        elif [ $2 == "22.04" ]
        then
            os_is_compat=1
        fi
    fi

    echo "os_is_compat = ${os_is_compat}"

    if [ $os_is_compat -eq 0 ]
    then
        echo "ERROR! This tool is only tested and validated for Ubuntu 20.04, 22.04"
        # exit 1
    fi
}
init_os_verify_check $OS $VER

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

hint_install_python() {
    if [ $1 == "Ubuntu" ]
    then
        if [ $2 == "20.04" ]
        then
            echo "Try the following commands:"
            echo "sudo apt install python3.9"
        fi
    fi
}

# check if python is installed/exists
get_python_which=$(which python3)
if [ $? -ne 0 ]
then
    echo "ERROR! Python3 not found, cannot continue. Please install at least python 3.9"
    exit $?
fi

# Python version check
get_python_version=$(${get_latest_python_full_path} -V)
if [ $? -ne 0 ]
then
    echo "ERROR! Unable to get python version"
    exit $?
fi

echo "Python Version: ${get_python_version}"
get_ver_only=$(echo ${get_python_version} | grep -oP [0-9]+\.[0-9]+ | head -1)
vercomp ${get_ver_only} ${min_req_python_ver}

# echo "do_vercomp = ${?}"
# 0 : A = B
# 1 : A > B
# 2 : B > A
if [ $? -eq 2 ]
then
    echo "ERROR! Python must be at least version ${min_req_python_ver}"
    hint_install_python $OS $VER
    exit $?
fi

echo "At least python ${min_req_python_ver} found"
# PIP check
get_pip_ver_text=$(${get_latest_python_full_path} -m pip -V)
if [ $? -ne 0 ]
then
    echo "ERROR! PIP not found or not installed. Will attempt to install."
    echo "Executing 'curl -sS https://bootstrap.pypa.io/get-pip.py | ${get_latest_python_full_path}'"
    curl -sS https://bootstrap.pypa.io/get-pip.py | $get_latest_python_full_path
    # echo See https://pip.pypa.io/en/stable/installation/
    # exit $?
fi

# PIP check
get_pip_ver_text=$(${get_latest_python_full_path} -m pip -V)
if [ $? -ne 0 ]
then
    echo "ERROR! PIP Failed to install."
    echo See https://pip.pypa.io/en/stable/installation/
    # exit $?
fi

echo "PIP Found: ${get_pip_ver_text}"

# PIP Version number only
# echo  | grep -oP "^pip \d+\.\d+\.\d+" | head -1 | grep -oP "\d+\.\d+\.\d+"

# Install python reqs
# sudo python3 -m pip install -r requirements.txt

# sudo -H pip3 install --ignore-installed PyYAML
$get_latest_python_full_path -m pip install --ignore-installed PyYAML

# sudo -H pip3 install --ignore-installed pytz
$get_latest_python_full_path -m pip install --ignore-installed pytz

$get_latest_python_full_path -m pip install --ignore-installed requests

$get_latest_python_full_path -m pip install --ignore-installed colorlog

# create service user
# gl_replay_service
sudo adduser --system --disabled-password --disabled-login --home /var/empty --no-create-home --quiet --force-badname --group gl_replay_service

# service dir
sudo mkdir -p /opt/graylog/log-replay

# copy files
sudo cp -f service-wrapper.sh /opt/graylog/log-replay
sudo chmod +x /opt/graylog/log-replay/service-wrapper.sh
sudo cp -f ../*.py /opt/graylog/log-replay
sudo cp -f ../*.yml /opt/graylog/log-replay

sudo mkdir -p /opt/graylog/log-replay/Event\ Files
sudo cp -f ../Event\ Files/*.events /opt/graylog/log-replay/Event\ Files

# prepopulate log file
touch /opt/graylog/log-replay/log.log

# set owner
sudo chown -R gl_replay_service:gl_replay_service /opt/graylog/log-replay

# install service.....
sudo cp -f gl-log-replay.service /etc/systemd/system/gl-log-replay.service

sudo systemctl daemon-reload

sudo systemctl enable gl-log-replay.service
# sudo systemctl start gl-log-replay.service

# add watchdog

# updater
sudo mkdir -p /opt/graylog/log-replay-updater
sudo chown -R root:root /opt/graylog/log-replay-updater
sudo touch /opt/graylog/log-replay-updater/token
sudo chmod 600 /opt/graylog/log-replay-updater/token
sudo cp updater.sh /opt/graylog/log-replay-updater/
sudo chmod +x /opt/graylog/log-replay-updater/updater.sh

echo "Installed to: /opt/graylog/log-replay"
echo "Installed Service: gl-log-replay"
echo "Service is stopped. Configure overrides.yml before starting service"
