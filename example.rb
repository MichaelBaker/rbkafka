#!/usr/bin/env ruby

$LOAD_PATH << 'lib'

require 'rb_kafka'

BROKER          = 'localhost:9092'
TOPIC           = 'topic'
PARTITION       = 0
CONSUME_WAIT_MS = 1000

LOG_DEBUG = 7

conf = RbKafka.rd_kafka_conf_new

rk = RbKafka.rd_kafka_new(:consumer, conf, '', 256)
unless rk
  warn "Could not initialize Kafka client: #{err.read_string}"
  exit 1
end

RbKafka.rd_kafka_set_log_level(rk, LOG_DEBUG)

if RbKafka.rd_kafka_brokers_add(rk, BROKER) == 0
  warn 'No brokers added'
  exit 1
end
tconf = RbKafka.rd_kafka_topic_conf_new
topic = RbKafka.rd_kafka_topic_new(rk, TOPIC, tconf)

if RbKafka.rd_kafka_consume_start(topic, PARTITION, RbKafka::RD_KAFKA_OFFSET_BEGINNING) == -1
  warn "Consume failed"
  exit 1
end

puts "Consuming as: #{RbKafka.rd_kafka_name(rk)}"

loop do
  m = RbKafka.rd_kafka_consume(topic, PARTITION, CONSUME_WAIT_MS)
  msg = RbKafka::RdKafkaMessageS.new(m)
  if !msg.null?
    if msg[:err] == :no_error
      puts "#{msg[:offset]}: #{msg[:payload].read_string_length(msg[:len])}"
      RbKafka.rd_kafka_message_destroy(msg)
    else
      warn msg[:err]
    end
  end
end

RbKafka.rd_kafka_destroy(rk)
