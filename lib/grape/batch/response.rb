class Grape::Batch::Response
  def self.format(status, headers, response, env)
    if response
      body = response.respond_to?(:body) ? response.body.join : response.join
      parsing_failed = true

      begin
        result = MultiJson.decode(body)
        parsing_failed = false
      rescue MultiJson::ParseError
        # Captain planet to the rescue
      end
    end

    if parsing_failed || result.empty?
      status = 404
      result = { 'error' => "#{env['PATH_INFO']} not found" }
    end

    (200..299).include?(status) ? { success: result } : { code: status, error: result['error'] }
  end
end
