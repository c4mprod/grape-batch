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
        return @app.call(env) unless is_batch_request?(env)
        batch_call(env)
      end

      def batch_call(env)
        @logger.prepare(env).batch_begin

        begin
          status = 200
          batch_requests = Grape::Batch::Validator::parse(env, @batch_size_limit)
          result = dispatch(env, batch_requests)
          body = MultiJson.encode(result)
        rescue Grape::Batch::RequestBodyError, Grape::Batch::TooManyRequestsError => e
          e.class == TooManyRequestsError ? status = 429 : status = 400
          body = e.message
        end

        @logger.batch_end
        Rack::Response.new(body, status, { 'Content-Type' => 'application/json' })
      end

      private

      def is_batch_request?(env)
        env['PATH_INFO'].start_with?(@api_path) &&
          env['REQUEST_METHOD'] == 'POST' &&
          env['CONTENT_TYPE'] == 'application/json'
      end

      def dispatch(env, batch_requests)
        env['api.session'] = @session_proc.call(env)

        # iterate
        batch_env = env.dup
        batch_requests.map do |request|
          # init env for Grape resource
          tmp_env = Grape::Batch::Request.new(batch_env, request).build
          status, headers, response = @app.call(tmp_env)

          # format response
          @response_klass.format(status, headers, response)
        end
      end
    end
  end
end
