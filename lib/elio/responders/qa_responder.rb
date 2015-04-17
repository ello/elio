module Elio
  module Responders
    class QAResponder < Bitbot::Responder
      category 'Process'

      help 'qa', description: 'Pop someone off of the QA stack, cycles them to the back'
      help 'add :name to QA', description: 'Add someone to the QA cycle by name'
      help 'remove :name from QA', description: 'Remove someone from the QA cycle by name'
      help 'show qa', description: 'Show everyone in the QA cycle'

      route :qa, /^qa$/ do
        if name = redis.next_name
          respond_with "#{name} is up for QA."
        else
          respond_with 'No one in the QA list! Add someone with "add :name to qa"'
        end
      end

      route :add, /^add (.*) to QA$/i do |name|
        redis.add_name name
        respond_with "Added #{name} to the QA cycle"
      end

      route :remove, /^remove (.*) from QA$/i do |name|
        redis.remove_name name
        respond_with "Removed #{name} from the QA cycle"
      end

      route :show, /^show qa$/ do
        names = redis.names

        if names.length > 0
          respond_with "I have #{names.inspect} in the QA cycle."
        else
          respond_with "Nobody in the QA cycle!"
        end
      end

      def redis
        @redis ||= RedisHelper.new(connection)
      end

      class RedisHelper
        NAMES_KEY = 'elio:qa_names'

        def initialize(connection)
          @connection = connection
        end

        def names
          @connection.lrange(NAMES_KEY, 0, -1)
        end

        def next_name
          @connection.rpoplpush(NAMES_KEY, NAMES_KEY)
        end

        def add_name(name)
          @connection.lpush(NAMES_KEY, name)
        end

        def remove_name(name)
          @connection.lrem(NAMES_KEY, 0, name)
        end
      end
    end
  end
end
