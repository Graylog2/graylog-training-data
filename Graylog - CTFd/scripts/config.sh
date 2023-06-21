#Load Abe's SwapShop!
docker run -p 7000:80 -d --restart always --log-driver gelf --log-opt gelf-address=tcp://localhost:12201 blueteamninja/swagshop
docker run -p 8080:80 -d --restart always tarampampam/webhook-tester

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

#Dan's Log magic goes here