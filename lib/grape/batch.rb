require 'grape/batch/error'
require 'grape/batch/parser'
require 'grape/batch/response'
require 'grape/batch/version'
require 'multi_json'

module Grape
  module Batch
    class Base
      def initialize(app, opt = {})
        @app = app
        @limit = opt[:limit] || 10
        @path = opt[:path] || '/batch'
        @response_klass = opt[:formatter] || Grape::Batch::Response
      end

      def call(env)
        return @app.call(env) unless is_batch_request?(env)
        batch_call(env)
      end

      def batch_call(env)
        status = 200
        headers = {'Content-Type' => 'application/json'}

        begin
          batch_requests = Grape::Batch::Validator::parse(env, @limit)
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
        env['PATH_INFO'].start_with?(@path) &&
            env['REQUEST_METHOD'] == 'POST' &&
            env['CONTENT_TYPE'] == 'application/json'
      end

      def dispatch(env, batch_requests)
        request_env = env.dup

        batch_requests.map do |request|
          method = request['method']
          path = request['path']
          body = request['body'].is_a?(Hash) ? request['body'] : {}

          request_env['REQUEST_METHOD'] = method
          request_env['PATH_INFO'] = path
          if method == 'GET'
            request_env['rack.input'] = StringIO.new('{}')
            request_env['QUERY_STRING'] = URI.encode_www_form(body.to_a)
          else
            request_env['rack.input'] = StringIO.new(MultiJson.encode(body))
          end

          status, headers, response = @app.call(request_env)

          @response_klass::format(status, headers, response)
        end
      end
    end
  end
end
