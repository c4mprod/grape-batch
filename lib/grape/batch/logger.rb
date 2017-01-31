module Grape
  module Batch
    # Main class logger
    class Logger
      def prepare(env)
        rack_timeout_info = env['rack-timeout.info'][:id] if env['rack-timeout.info']
        @request_id = env['HTTP_X_REQUEST_ID'] || rack_timeout_info || SecureRandom.hex
        @logger = Grape::Batch.configuration.logger || rails_logger || default_logger
        self
      end

      def default_logger
        logger = Logger.new($stdout)
        logger.level = Logger::INFO
        logger
      end

      def rails_logger
        defined?(::Rails) && ::Rails.respond_to?(:logger) && ::Rails.logger
      end

      def batch_begin
        @logger.info("--- Grape::Batch #{@request_id} BEGIN")
        self
      end

      def batch_end
        @logger.info("--- Grape::Batch #{@request_id} END")
        self
      end

      def info(message)
        @logger.info(message)
        self
      end
    end
  end
end
