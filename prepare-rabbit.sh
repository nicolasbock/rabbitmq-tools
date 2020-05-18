#!/bin/bash

set -u -x

broker=$1
user=$2
password=$3
vhost=$4

ssh ${broker} -- sudo rabbitmqctl add_user ${user} ${password}
ssh ${broker} -- sudo rabbitmqctl add_vhost ${vhost}
ssh ${broker} -- sudo rabbitmqctl set_permissions -p ${vhost} ${user} \".*\" \".*\" \".*\"
