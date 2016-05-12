module Grape
  module Batch
    class Base
      SESSION_HEADER = 'api.session'.freeze
      TOKEN_HEADER = 'HTTP_X_API_TOKEN'.freeze

      def initialize(app)
        @app = app
        @logger = Grape::Batch::Logger.new
      end

      def call(env)
        return @app.call(env) unless batch_request?(env)

        # Handle batch requests
        @logger.prepare(env).batch_begin
        body, status = batch_call(env)
        @logger.batch_end

        # Return Rack formatted response
        Rack::Response.new(body, status, 'Content-Type' => 'application/json')
      end

      def batch_call(env)
        batch_requests = Grape::Batch::Validator.parse(env, Grape::Batch.configuration.limit)
        [MultiJson.encode(dispatch(env, batch_requests)), 200]

      rescue Grape::Batch::RequestBodyError, Grape::Batch::TooManyRequestsError => e
        [e.message, e.class == TooManyRequestsError ? 429 : 400]
      end

      def dispatch(env, batch_requests)
        call_api_session_proc(env)

        # Call batch request
        batch_requests.map do |batch_request|
          batch_env = Grape::Batch::Request.new(env, batch_request).build
          call_batched_request(batch_env)
        end
      end

      def call_batched_request(env)
        status, headers, response = @app.call(env)
        Grape::Batch.configuration.formatter.format(status, headers, response)
      end

      private

      def batch_request?(env)
        env['PATH_INFO'].start_with?(Grape::Batch.configuration.path) &&
          env['REQUEST_METHOD'] == 'POST' && env['CONTENT_TYPE'] == 'application/json'
      end

      def call_api_session_proc(env)
        return unless Grape::Batch.configuration.session_proc
        env[SESSION_HEADER] = Grape::Batch.configuration.session_proc.call(env)
      end
    end
  end
end
