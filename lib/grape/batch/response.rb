module Grape
  module Batch
    # Format batch request response
    class Response
      def self.format(status, _headers, response)
        if response
          body = response.respond_to?(:body) ? response.body.join : response.join
          result = MultiJson.decode(body)
        end

        if (200..299).include?(status)
          { success: result }
        else
          { code: status, error: result['error'] }
        end
      end
    end
  end
end
