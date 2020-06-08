#!/bin/bash

set -u -e

usage() {
  cat <<EOF
Usage:

$(basename $0) RABBIT RABBIT [RABBIT [RABBIT [...]]]
EOF
}

on_exit() {
  if (( $? != 0 )); then
    usage
    exit 1
  fi
}

trap on_exit EXIT

declare -a brokers

while (( $# > 0 )); do
  case $1 in
    --help|-h)
      usage
      exit 0
      ;;
    *)
      brokers=( "${brokers[@]}" "$1" )
      ;;
  esac
  shift
done

cookie=$(mktemp)

set -x

lxc file pull ${brokers[0]}/var/lib/rabbitmq/.erlang.cookie ${cookie}
for (( i = 1; i < ${#brokers[@]}; i++ )); do
  lxc file push ${cookie} ${brokers[${i}]}/var/lib/rabbitmq/.erlang.cookie
  lxc exec ${brokers[${i}]} -- chown rabbitmq: /var/lib/rabbitmq/.erlang.cookie
  lxc exec ${brokers[${i}]} -- sudo systemctl restart rabbitmq-server
  lxc exec ${brokers[${i}]} -- sudo rabbitmqctl stop_app
  lxc exec ${brokers[${i}]} -- sudo rabbitmqctl join_cluster rabbit@${brokers[0]}
  lxc exec ${brokers[${i}]} -- sudo rabbitmqctl start_app
done

lxc exec ${brokers[0]} -- sudo rabbitmqctl cluster_status
