#!/usr/bin/env python

import argparse
import pika
import amqp
import sys


def parse_command_line():
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "BROKER",
        help="The IP address or hostname of the broker, default = %(default)s",
        default="localhost",
        nargs="+")
    parser.add_argument(
        "--durable",
        action="store_true")
    parser.add_argument(
        "--queue",
        help="The queue to use, default = %(default)s",
        type=str,
        default="test_queue")
    parser.add_argument(
        "--send",
        metavar="MSG",
        help="Send MSG to queue")
    parser.add_argument(
        "--get",
        help="Get one message from queue",
        action="store_true")
    parser.add_argument(
        "--list",
        help="List messages in queue",
        action="store_true")
    parser.add_argument(
        "--delete",
        metavar="QUEUE",
        help="Delete QUEUE")
    return parser.parse_args()


def open_connection(broker, queue_name, durable):
    try:
        connection = pika.BlockingConnection(pika.ConnectionParameters(
            host=broker,
            virtual_host="tester",
            credentials=pika.PlainCredentials('tester', 'linux')
        ))
    except pika.exceptions.AMQPConnectionError:
        print("connection failure for %s" % broker)
        return None, None
    channel = connection.channel()
    channel.queue_declare(queue_name, durable=durable)

    return connection, channel


def main(options):
    for broker in options.BROKER:
        connection, channel = open_connection(
            broker, options.queue, options.durable)
        if connection is None:
            continue
        if options.send:
            print("sending one message")
            channel.basic_publish(exchange="",
                                  routing_key=options.queue,
                                  body=options.send)
            break

        elif options.get:
            print("getting one message")
            method_frame, header_frame, body = channel.basic_get(options.queue)
            if method_frame:
                print("message %s %s '%s'" %
                      (method_frame, message_frame, body.decode("utf-8")))
                channel.basic_ack(method_frame.delivery_tag)
            else:
                print("no message received")

        elif options.list:
            print("message list on broker %s" % broker)
            messages = []
            while True:
                method_frame, header_frame, body = channel.basic_get(
                    options.queue)
                if method_frame:
                    messages.append((method_frame, header_frame, body))
                    channel.basic_ack(method_frame.delivery_tag)
                    print("message %s %s body: '%s'" %
                          (method_frame, header_frame, body.decode("utf-8")))
                else:
                    break
            for _, _, body in messages:
                channel.basic_publish(exchange="",
                                      routing_key=options.queue,
                                      body=body)

        elif options.delete:
            print("deleting queue %s" % options.delete)
            channel.queue_delete(options.delete)
            break

        connection.close()


if __name__ == "__main__":
    main(parse_command_line())
