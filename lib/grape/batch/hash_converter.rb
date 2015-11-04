module Grape
  module Batch
    class HashConverter
      def self.encode(value, key = nil, out_hash = {})
        case value
          when Hash
            value.each { |k, v| encode(v, append_key(key, k), out_hash) }
            out_hash
          when Array
            value.each { |v| encode(v, "#{key}[]", out_hash) }
            out_hash
          when nil
            ''
          else
            out_hash[key] = value
            out_hash
        end
      end

      private

      def self.append_key(root_key, key)
        root_key.nil? ? :"#{key}" : :"#{root_key}[#{key.to_s}]"
      end
    end
  end
end
