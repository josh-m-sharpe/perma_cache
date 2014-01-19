require "perma_cache/version"

module PermaCache
  def self.version= v
    @version = v
  end

  def self.version
    @version || 1
  end

  def self.cache
    @cache ||= Rails.cache
  end

  def self.cache= c
    @cache = c
  end

  def perma_cache(method_name, options = {})
    class_eval do
      define_method "#{method_name}_key" do
        key = []
        key << "perma_cache"
        key << "v#{PermaCache.version}"

        key << ((self.name rescue nil) || self.class.name)

        if options[:obj]
          obj = send(options[:obj])
          case obj
          when ActiveRecord::Base
            key << obj.class.model_name.cache_key
            key << obj.id
          else
            key << options[:obj]
            key << obj
          end
        end

        key << self.perma_cache_key rescue nil
        key << method_name
        key = key.flatten.reject(&:blank?).join('/').downcase
        puts key unless Rails.env.test?
        key
      end

      define_method "#{method_name}!" do
        send("#{method_name}_without_perma_cache").tap do |result|
          PermaCache.cache.write(send("#{method_name}_key"), result, :expires => options[:expires])
        end
      end

      define_method "#{method_name}_get_perma_cache" do
        PermaCache.cache.read(send("#{method_name}_key"))
      end

      define_method "#{method_name}_with_perma_cache" do
        send("#{method_name}_get_perma_cache") ||
        send("#{method_name}!")
      end
      alias_method_chain method_name, :perma_cache
    end
  end
end

Object.send(:include, PermaCache)

