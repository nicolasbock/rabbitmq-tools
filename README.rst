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
   $ ./prepare-rabbit.sh 10.5.0.1

This script will create a test user and a test vhost. Detailed usage
is:

.. code-block::
   Usage:

   prepare-rabbit.sh [options] BROKER

   Where BROKER is the address of the RabbitMQbroker to prepare.

   Options:

   --user USER       The username to set
   --password PASS   The password for USER
   --vhost VHOST     The vhost to create

Set up a `virtualenv` to run the actual test script:

.. code-block:: bash
   $ virtualenv venv
   $ . venv/bin/activate
   $ pip install -r requirements.txt
   $ python setup.py install

Now send a message:

.. code-block:: bash
   $ test-rabbit.py 10.5.0.1 --send "My first message"

Full usage:

.. code-block::
   usage: test-rabbit.py [-h] [--durable] [--queue QUEUE] [--send MSG] [--get]
                         [--list] [--user USER] [--password PASSWORD]
                         [--vhost VHOST] [--delete QUEUE]
                         BROKER [BROKER ...]

   positional arguments:
     BROKER               The IP address or hostname of the broker, default =
                          localhost

   optional arguments:
     -h, --help           show this help message and exit
     --durable
     --queue QUEUE        The queue to use, default = test_queue
     --send MSG           Send MSG to queue
     --get                Get one message from queue
     --list               List messages in queue
     --user USER          The user to use for the RabbitMQ connection, default =
                          tester
     --password PASSWORD  The password to use for the RabbitMQ connection,
                          default = linux
     --vhost VHOST        The vhost to use for the RabbitMQ connection, default =
                          tester
     --delete QUEUE       Delete QUEUE
