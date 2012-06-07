#!/bin/sh

sudo rabbitmqctl add_vhost /
sudo rabbitmqctl add_user guest guest
sudo rabbitmqctl set_permissions -p / guest ".*" ".*" ".*"

sudo rabbitmq-server
