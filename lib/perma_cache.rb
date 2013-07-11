require "perma_cache/version"

module PermaCache

  def perma_cache(method_name, options = {})
    class_eval do
      define_method "#{method_name}_key" do
        key = perma_cache_key(self)
        key << send(options.delete(:obj)).cache_key if options[:obj]
        key << method_name
        puts key = key.flatten.reject(&:blank?).join('/').downcase
        key
      end

      define_method "#{method_name}_inst_var" do
        puts inst_var = "@" + send("#{method_name}_key").gsub(/[^0-9a-zA-Z]/,'_')
        inst_var
      end

      define_method "#{method_name}!" do
        send("#{method_name}_without_perma_cache").tap do |result|
          instance_variable_set(send("#{method_name}_inst_var"), result)
          puts "whoamigod writing cache"
          Rails.cache.write(send("#{method_name}_key"), result, :expires_in => 120.hours)
        end
      end

      define_method "#{method_name}_with_perma_cache" do
        instance_variable_get(send("#{method_name}_inst_var")) ||
        Rails.cache.read(send("#{method_name}_key")) ||
        send("#{method_name}!")
      end
      alias_method_chain method_name, :perma_cache

      unless respond_to?(:perma_cache_key)
        def perma_cache_key(obj)
          [
            "perma_cache",
            # MEMOIZER_VERSION,
            (obj.cache_key rescue nil) || (obj.name rescue nil) || obj.class.name
          ]
        end
      end
    end
  end
end

Module.send(:include, PermaCache)

