require 'active_support'
require 'grape/batch/log_subscriber'
require 'grape/batch/version'
require 'grape/batch/errors'
require 'grape/batch/configuration'
require 'grape/batch/hash_converter'
require 'grape/batch/parser'
require 'grape/batch/response'
require 'multi_json'

module Grape
  module Batch
    class Base
      def initialize(app)
        @app = app
        @response_klass = Grape::Batch.configuration.formatter
      end

      def call(env)
        return @app.call(env) unless is_batch_request?(env)
        batch_call(env)
      end

      def batch_call(env)
        status = 200
        headers = { 'Content-Type' => 'application/json' }

        begin
          batch_requests = Grape::Batch::Validator::parse(env, Grape::Batch.configuration.limit)
          result = dispatch(env, batch_requests)
          body = MultiJson.encode(result)
        rescue Grape::Batch::RequestBodyError, Grape::Batch::TooManyRequestsError => e
          e.class == TooManyRequestsError ? status = 429 : status = 400
          body = e.message
        end

        [status, headers, [body]]
      end

      private

      def is_batch_request?(env)
        env['PATH_INFO'].start_with?(Grape::Batch.configuration.path) &&
          env['REQUEST_METHOD'] == 'POST' &&
          env['CONTENT_TYPE'] == 'application/json'
      end

      def dispatch(env, batch_requests)
        ActiveSupport::Notifications.instrument 'dispatch.batch' do |event|
          event[:requests] = []

          session_data = env[Grape::Batch.configuration.session_header]
          env['api.session'] = Grape::Batch.configuration.session_proc.call(session_data)

          # iterate
          batch_env = env.dup
          batch_requests.map do |request|
            # init env for Grape resource
            tmp_env = prepare_tmp_env(batch_env, request)
            status, headers, response = @app.call(tmp_env)

            # format response
            @response_klass::format(status, headers, response).tap do |formatted_response|
              # log call
              event[:requests] << [tmp_env, formatted_response]
            end
          end
        end
      end

      def prepare_tmp_env(tmp_env, request)
        method = request['method']
        path = request['path']
        body = request['body'].is_a?(Hash) ? request['body'] : {}
        query_string = ''
        rack_input = '{}'

        if method == 'GET'
          query_string = URI.encode_www_form(HashConverter.encode(body).to_a)
        else
          rack_input = StringIO.new(MultiJson.encode(body))
        end

        tmp_env['REQUEST_METHOD'] = method
        tmp_env['PATH_INFO'] = path
        tmp_env['QUERY_STRING'] = query_string
        tmp_env['rack.input'] = rack_input
        tmp_env
      end
    end
  end
end
