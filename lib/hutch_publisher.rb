require 'connection_pool'
require 'hutch'
require 'json'
require 'securerandom'

module HutchPublisher
  VERSION = '0.1.0'

  class Error < StandardError
    attr_accessor :messages

    def initialize(message, messages = [])
      super(message)
      @messages = messages
    end
  end

  @lock ||= Mutex.new

  def self.connect(options = {})
    @lock.synchronize do
      unless defined?(@channel_pool) || @channel_pool
        broker = Hutch::Broker.new
        broker.open_connection!

        @channel_pool = ConnectionPool.new(size: options[:pool] || 5, timeout: options[:timeout] || 5) {
          broker.open_channel!
        }
      end
    end
  end

  def self.publish(routing_key, message_or_messages, properties = {})
    HutchPublisher.connect

    properties[:retry_count] ||= 3

    messages = message_or_messages.kind_of?(Array) ? message_or_messages : [message_or_messages]

    @channel_pool.with do |channel|
      channel.confirm_select
      exchange = channel.topic(Hutch::Config.get(:mq_exchange), durable: true)

      messages.each do |message|
        exchange.publish(message.to_json, {
            routing_key: routing_key,
            persistent: true,
            message_id: SecureRandom.uuid,
            timestamp: Time.now.to_i,
            content_type: 'application/json'
          }.merge(properties))
      end

      success = channel.wait_for_confirms
      unless success
        failed_messages = channel.nacked_set.map { |message_index|
          messages[message_index]
        }

        if properties[:retry_count] > 0
          HutchPublisher.publish(routing_key, failed_messages, properties.merge(
              retry_count: properties[:retry_count] - 1
            ))
        else
          raise HutchPublisher::Error.new('Could not publish some messages to the queue', failed_messages)
        end
      end
    end
  end

  def self.disconnect
    @lock.synchronize do
      if defined?(@channel_pool) && @channel_pool
        @channel_pool.shutdown { |channel|
          channel.close
        }
      end
    end
  end
end
