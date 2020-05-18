==================
 RabbitMQ Testing
==================

This repository contains a simple test script to test a RabbitMQ
cluster.

Usage
=====

Let's say we have a RabbitMQ cluster at IP address `10.5.0.{1,2,3}`.
Prepare the cluster by running:

.. code-block:: bash
   ./prepare-rabbit.sh 10.5.0.1

This script will create a test user and a test vhost. Detailed usage
is:

.. code::
   Usage:

   prepare-rabbit.sh [options] BROKER

   Where BROKER is the address of the RabbitMQbroker to prepare.

   Options:

   --user USER       The username to set
   --password PASS   The password for USER
   --vhost VHOST     The vhost to create
