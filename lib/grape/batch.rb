require 'grape/batch/configuration'
require 'grape/batch/errors'
require 'grape/batch/logger'
require 'grape/batch/request'
require 'grape/batch/response'
require 'grape/batch/validator'
require 'grape/batch/version'
require 'multi_json'

module Grape
  module Batch
    # Gem main class
    class Base
      def initialize(app)
        @app = app
        @response_klass = Grape::Batch.configuration.formatter
        @batch_size_limit = Grape::Batch.configuration.limit
        @api_path = Grape::Batch.configuration.path
        @session_proc = Grape::Batch.configuration.session_proc
        @logger = Grape::Batch::Logger.new
      end

      def call(env)
        return @app.call(env) unless batch_request?(env)
        @logger.prepare(env).batch_begin
        batch_call(env)
      end

      def batch_call(env)
        begin
          status = 200
          batch_requests = Grape::Batch::Validator.parse(env, @batch_size_limit)
          body = MultiJson.encode(dispatch(env, batch_requests))
        rescue Grape::Batch::RequestBodyError, Grape::Batch::TooManyRequestsError => e
          e.class == TooManyRequestsError ? status = 429 : status = 400
          body = e.message
        end

        @logger.batch_end
        Rack::Response.new(body, status, 'Content-Type' => 'application/json')
      end

      private

      def batch_request?(env)
        env['PATH_INFO'].start_with?(@api_path) &&
          env['REQUEST_METHOD'] == 'POST' &&
          env['CONTENT_TYPE'] == 'application/json'
      end

      def dispatch(env, batch_requests)
        # Call session proc
        env['api.session'] = @session_proc.call(env)

        # Prepare batch request env
        request_env = env.dup

        # Call batch request
        batch_requests.map do |batch_request|
          batch_env = Grape::Batch::Request.new(request_env, batch_request).build
          status, headers, response = @app.call(batch_env)
          @response_klass.format(status, headers, response)
        end
      end
    end
  end
end
