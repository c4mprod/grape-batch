require 'grape/batch/converter'

module Grape
  module Batch
    # Prepare batch request
    class Request
      def initialize(env, batch_request)
        @env = env
        @batch_request = batch_request
      end

      def method
        @batch_request['method']
      end

      def path
        @batch_request['path']
      end

      def body
        @body ||= @batch_request['body'].is_a?(Hash) ? @batch_request['body'] : {}
      end

      def query_string
        @query_string ||= method == 'GET' ? URI.encode_www_form(Converter.encode(body).to_a) : ''
      end

      def rack_input
        @rack_input ||= method == 'GET' ? '{}' : StringIO.new(MultiJson.encode(body))
      end

      def build
        @env['REQUEST_METHOD'] = method
        @env['PATH_INFO'] = path
        @env['QUERY_STRING'] = query_string
        @env['rack.input'] = rack_input
        @env
      end
    end
  end
end
