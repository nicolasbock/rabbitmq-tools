#!/bin/bash

set -u

usage() {
      cat <<EOF
Usage:

$(basename $0) [options] [user@]BROKER_IP

Where BROKER is the address of the RabbitMQbroker to prepare.

Options:

--user USER       	The username to set
--password PASS   	The password for USER
--vhost VHOST     	The vhost to create
--transport {lxc,ssh}   How to connect to the brokers
EOF
}

_ssh() {
  ssh ${broker} -- "${@}"
}

_lxc() {
  lxc exec ${broker} -- "${@}"
}

on_exit() {
  if (( $? != 0 )); then
    usage
    exit 1
  fi
}

trap on_exit EXIT

user=tester
password=linux
vhost=tester
transport=ssh

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
    --help)
      usage
      exit
      ;;
    *)
      broker=$1
      ;;
  esac
  shift
done

set -x

_${transport} sudo rabbitmqctl add_user ${user} ${password}
_${transport} sudo rabbitmqctl add_vhost ${vhost}
_${transport} sudo rabbitmqctl set_permissions -p ${vhost} ${user} ".*" ".*" ".*"
_${transport} sudo rabbitmqctl set_policy -p ${vhost} HA ".*" '{"ha-mode": "all"}'
_${transport} sudo rabbitmqctl list_permissions -p ${vhost}
_${transport} sudo rabbitmqctl list_policies -p ${vhost}
