module Grape
  module Batch
    # Convert hash to www form url params
    class Converter
      class << self
        def encode(value, key = nil, out_hash = {})
          case value
            when Hash
              value.each { |k, v| encode(v, append_key(key, k), out_hash) }
            when Array
              value.each { |v| encode(v, "#{key}[]", out_hash) }
            else
              out_hash[key] = value
          end

          value ? out_hash : ''
        end

        def append_key(root_key, key)
          root_key ? :"#{root_key}[#{key.to_s}]" : :"#{key}"
        end
      end
    end
  end
end
