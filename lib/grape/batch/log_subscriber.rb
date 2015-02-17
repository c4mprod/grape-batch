module Grape
  module Batch
    class LogSubscriber < ActiveSupport::LogSubscriber
      def dispatch(event)
        requests = event.payload[:requests]

        if logger.debug?
          debug_log(requests)
        else
          info_log(requests)
        end
      end

      private

      def debug_log(requests)
        logger.info 'grape/batch'

        requests.map do |params|
          request, response = params
          logger.info " method=#{request['REQUEST_METHOD']} path=#{request['PATH_INFO']}"

          if request['REQUEST_METHOD'] == 'GET'
            unless request['QUERY_STRING'].empty?
              logger.debug "  params: #{request['QUERY_STRING'].to_s}"
            end
          else
            if request['rack.input'].respond_to? :string
              logger.debug "  body: #{request['rack.input'].string}"
            end
          end
          logger.debug "  response: #{response.to_s}"
        end
      end

      def info_log(requests)
        messages = []
        requests.each do |params|
          request, response = params
          messages << "method=#{request['REQUEST_METHOD']} path=#{request['PATH_INFO']}"
        end

        logger.info 'grape/batch ' + messages.join(', ')
      end

      def logger
        @logger ||= Grape::Batch.configuration.logger || rails_logger || default_logger
      end

      def default_logger
        logger = Logger.new($stdout)
        logger.level = Logger::INFO
        logger
      end

      # Get the Rails logger if it's defined.
      def rails_logger
        defined?(::Rails) && ::Rails.respond_to?(:logger) && ::Rails.logger
      end
    end
  end
end

Grape::Batch::LogSubscriber.attach_to(:batch)
