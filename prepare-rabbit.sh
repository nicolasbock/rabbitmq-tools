#!/bin/bash

set -u -e

usage() {
      cat <<EOF
Usage:

$(basename $0) [options] [user@]BROKER_IP

Where BROKER is the address of the RabbitMQbroker to prepare.

Options:

--user USER       The username to set
--password PASS   The password for USER
--vhost VHOST     The vhost to create
EOF
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

ssh ${broker} -- sudo rabbitmqctl add_user ${user} ${password}
ssh ${broker} -- sudo rabbitmqctl add_vhost ${vhost}
ssh ${broker} -- sudo rabbitmqctl set_permissions -p ${vhost} ${user} \".*\" \".*\" \".*\"
