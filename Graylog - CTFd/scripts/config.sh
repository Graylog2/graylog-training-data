#Load Abe's SwapShop!
docker run -p 7000:80 -d --restart always --log-driver gelf --log-opt gelf-address=tcp://localhost:12201 blueteamninja/swagshop
docker run -p 8080:8080 -d --restart always tarampampam/webhook-tester

#Ricks Sysadmin stuffs!
# get the docker bridge so we can add the lxc container to it, pretty sure this is illegal in 12 states
docker_bridge="br-"$(docker network list | grep 'graylog_default' | cut -f 1 -d ' ')
# init LXD with a config
cat <<EOF | lxd init --preseed
config:
  images.auto_update_interval: "0"
networks: []
storage_pools:
- config: {}
  description: ""
  name: default
  driver: dir
profiles:
- config: {}
  description: ""
  devices:
    eth0:
      name: eth0
      nictype: bridged
      parent: $docker_bridge
      type: nic
    root:
      path: /
      pool: default
      type: disk
  name: default
cluster: null
EOF
# init the LXC container with ubuntu focal
lxc init images:ubuntu/focal/amd64 multivac
# setup static IP for multivac container
cat <<EOF>/var/snap/lxd/common/lxd/containers/multivac/rootfs/etc/netplan/10-lxc.yaml
network:
  version: 2
  ethernets:
    eth0:
      dhcp4: false
      dhcp-identifier: mac
      addresses: [172.18.10.10/16]
      gateway4: 172.18.0.1
      nameservers:
        addresses: [1.1.1.1]
EOF
# setup hosts file resolution for graylog container in multivac
graylog_ip=$(docker container inspect -f '{{ .NetworkSettings.Networks.graylog_default.IPAddress }}' graylog-graylog-1)
echo "$graylog_ip graylog" >> /var/snap/lxd/common/lxd/containers/multivac/rootfs/etc/hosts
# start multivac!
#lxc start multivac
# execute multivac config script
#lxc exec multivac -- bash -c "$(cat multivac_config.sh)"

#Dan's Log magic goes here