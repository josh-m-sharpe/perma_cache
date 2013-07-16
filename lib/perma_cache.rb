require "perma_cache/version"

module PermaCache
  def self.version= v
    @version ||= v
  end

  def self.version
    @version || 1
  end

  def perma_cache(method_name, options = {})
    class_eval do
      define_method "#{method_name}_key" do
        key = perma_cache_key(self)
        key << send(options[:obj]).cache_key if options[:obj]
        key << method_name
        puts key = key.flatten.reject(&:blank?).join('/').downcase
        key
      end

      define_method "#{method_name}!" do
        send("#{method_name}_without_perma_cache").tap do |result|
          Rails.cache.write(send("#{method_name}_key"), result, :expires_in => 72.hours)
        end
      end

      define_method "#{method_name}_with_perma_cache" do
        Rails.cache.read(send("#{method_name}_key")) ||
        send("#{method_name}!")
      end
      alias_method_chain method_name, :perma_cache

      unless respond_to?(:perma_cache_key)
        def perma_cache_key(obj)
          [
            "perma_cache",
            "v#{PermaCache.version}",
            (obj.cache_key rescue nil) || (obj.name rescue nil) || obj.class.name
          ]
        end
      end
    end
  end
end

Module.send(:include, PermaCache)

