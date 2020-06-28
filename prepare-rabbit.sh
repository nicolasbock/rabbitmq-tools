#!/bin/bash

set -u -e

usage() {
      cat <<EOF
Usage:

$(basename $0) [options] [user@]BROKER_IP [user@]BROKER_IP [[user@]BROKER_IP [[user@]BROKER_IP [...]]]

Where BROKER_IP is the address of the RabbitMQbroker to prepare.

Options:

--user USER       	The username to set
--password PASS   	The password for USER
--vhost VHOST     	The vhost to create
--transport {lxc,ssh}   How to connect to the brokers (default ${transport})
--ssh-key KEYFILE       The ssh key to use for the root user
EOF
}

_ssh() {
  local ip=$1
  shift
  ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null $ip -- "${@}"
 }

_lxc() {
  local name=$1
  shift
  lxc exec $name -- "${@}"
}

all_brokers() {
  for broker in "${brokers[@]}"; do
    _${transport} ${broker} "$@"
  done
}

on_exit() {
  if (( $? != 0 )); then
    usage
    exit 1
  fi
}

trap on_exit EXIT

add_sshkey() {
  for broker in ${brokers[@]}; do
    _${transport} ${broker} sudo bash -c 'cat >> /root/.ssh/authorized_keys' < "${keyfile}"
  done
}

install_rabbitmq() {
  all_brokers sudo apt --assume-yes install rabbitmq-server
}

cluster_rabbitmq() {
  local ip_address_1
  ip_address_1=${brokers[0]}
  if [[ ${transport} = lxc ]]; then
    ip_address_1=$(lxc list --format csv --columns 4 ${ip_address_1} | awk '{print $1}')
  fi
  local tempfile
  tempfile=$(mktemp)
  scp -o StrictHostKeyChecking=no \
    -o UserKnownHostsFile=/dev/null \
    root@${ip_address_1}:/var/lib/rabbitmq/.erlang.cookie \
    ${tempfile}
  for (( i = 1; i < ${#brokers[@]}; i++ )); do
    local ip_address_2
    ip_address_2=${brokers[${i}]}
    if [[ ${transport} = lxc ]]; then
      ip_address_2=$(lxc list --format csv --columns 4 ${ip_address_2} | awk '{print $1}')
    fi
    scp -o StrictHostKeyChecking=no \
      -o UserKnownHostsFile=/dev/null \
      ${tempfile} \
      root@${ip_address_2}:/var/lib/rabbitmq/.erlang.cookie
    ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@${ip_address_2} systemctl restart rabbitmq-server.service
    ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@${ip_address_2} rabbitmqctl stop_app
    ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@${ip_address_2} rabbitmqctl reset
    ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@${ip_address_2} rabbitmqctl join_cluster rabbit@${brokers[0]}
    ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@${ip_address_2} rabbitmqctl start_app
  done
}

configure_rabbitmq() {
  _${transport} ${brokers[0]} sudo rabbitmqctl add_user ${user} ${password}
  _${transport} ${brokers[0]} sudo rabbitmqctl add_vhost ${vhost}
  _${transport} ${brokers[0]} sudo rabbitmqctl set_permissions -p ${vhost} ${user} ".*" ".*" ".*"
  _${transport} ${brokers[0]} sudo rabbitmqctl set_policy -p ${vhost} HA ".*" '{"ha-mode": "all"}'
  _${transport} ${brokers[0]} sudo rabbitmqctl list_permissions -p ${vhost}
  _${transport} ${brokers[0]} sudo rabbitmqctl list_policies -p ${vhost}
}

user=tester
password=linux
vhost=tester
transport=ssh
keyfile=~/.ssh/id_rsa.pub
declare -a brokers

while (( $# > 0 )); do
  case $1 in
    --user)
      user=$2
      shift
      ;;
    --password)
      password=$2
      shift
      ;;
    --vhost)
      vhost=$2
      shift
      ;;
    --transport)
      transport=$2
      shift
      ;;
    --ssh-key)
      keyfile=$2
      shift
      ;;
    --help)
      usage
      exit
      ;;
    *)
      if [[ -v brokers ]]; then
        brokers=( "${brokers}" "$1" )
      else
        brokers=( "$1" )
      fi
      ;;
  esac
  shift
done

set -x

add_sshkey
install_rabbitmq
cluster_rabbitmq
configure_rabbitmq
