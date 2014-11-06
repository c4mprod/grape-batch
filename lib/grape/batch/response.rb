module Grape
  module Batch
    class Response
      def self.format(status, headers, response)
        if response
          body = response.respond_to?(:body) ? response.body.join : response.join
          result = MultiJson.decode(body)
        end

        (200..299).include?(status) ? {success: result} : {code: status, message: result['error']}
      end
    end
  end
end
