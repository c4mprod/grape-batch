require 'grape/batch/hash_converter'

module Grape
  module Batch
    class Request
      def initialize(env, batch_request)
        @env = env
        @batch_request = batch_request
      end

      def build
        method = @batch_request['method']
        path = @batch_request['path']
        body = @batch_request['body'].is_a?(Hash) ? @batch_request['body'] : {}
        query_string = ''
        rack_input = '{}'

        if method == 'GET'
          query_string = URI.encode_www_form(HashConverter.encode(body).to_a)
        else
          rack_input = StringIO.new(MultiJson.encode(body))
        end

        @env['REQUEST_METHOD'] = method
        @env['PATH_INFO'] = path
        @env['QUERY_STRING'] = query_string
        @env['rack.input'] = rack_input
        @env
      end
    end
  end
end
