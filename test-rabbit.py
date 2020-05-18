#!/usr/bin/env python

import argparse
import pika
import amqp
import sys

def parse_command_line():
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "BROKER",
        help="The IP address or hostname of the broker",
        nargs="+")
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
    return parser.parse_args()

def open_connection(broker):
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
    channel.queue_declare("test_queue", durable=False)

    return connection, channel

def main(options):
    for broker in options.BROKER:
        connection, channel = open_connection(broker)
        if connection is None:
            continue
        if options.send:
            print("sending one message")
            channel.basic_publish(exchange="",
                                  routing_key="test_queue",
                                  body=options.send)

        elif options.get:
            print("getting one message")
            method_frame, header_frame, body = channel.basic_get("test_queue")
            if method_frame:
                print("message %s %s '%s'" % (method_frame, message_frame, body.decode("utf-8")))
                channel.basic_ack(method_frame.delivery_tag)
            else:
                print("no message received")

        elif options.list:
            print("message list on broker %s" % options.BROKER)
            messages = []
            while True:
                method_frame, header_frame, body = channel.basic_get("test_queue")
                if method_frame:
                    messages.append((method_frame, header_frame, body))
                    channel.basic_ack(method_frame.delivery_tag)
                    print("message %s %s body: '%s'" % (method_frame, header_frame, body.decode("utf-8")))
                else:
                    break
            for _, _, body in messages:
                channel.basic_publish(exchange="",
                                      routing_key="test_queue",
                                      body=body)

        connection.close()

if __name__ == "__main__":
    main(parse_command_line())
