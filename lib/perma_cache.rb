require 'active_support/core_ext/module/aliasing'

require "perma_cache/version"

module PermaCache
  class UndefinedCache < StandardError ; end

  def self.version= v
    @version = v
  end

  def self.version
    @version || 1
  end

  def self.cache
    @cache || raise(UndefinedCache, "Please define a cache object: (PermaCache.cache = Rails.cache)")
  end

  def self.cache= c
    @cache = c
  end

  def self.build_key_from_object(obj)
    # Don't want to add this to Object
    Array.new.tap do |arr|
      if obj.respond_to?(:cache_key)
        arr << obj.cache_key
      else
        arr << obj.class.name

        if obj.respond_to?(:id)
          arr << obj.id
        end
      end
    end
  end

  def self.included(base)
    base.extend ClassMethods
  end

  module ClassMethods
    def perma_cache(method_name, options = {})
      class_eval do
        define_method "#{method_name}_base_key" do
          key = []
          key << "perma_cache"
          key << "v#{PermaCache.version}"

          key << PermaCache.build_key_from_object(self)

          if options[:obj]
            key << PermaCache.build_key_from_object(send(options[:obj]))
          end

          key << method_name

          if options[:version]
            key << "v#{options[:version]}"
          end

          key = key.flatten.reject do |k|
            (k.empty? rescue nil) ||
            (k.nil? rescue nil)
          end.join('/')

          key
        end

        define_method "#{method_name}_perma_cache_key" do
          [
            send("#{method_name}_base_key"),
            (send("#{method_name}_key") rescue nil)
          ].compact.join('/').gsub(' ','_')
        end

        define_method "#{method_name}!" do
          send("#{method_name}_without_perma_cache").tap do |result|
            PermaCache.cache.write(send("#{method_name}_perma_cache_key"), result, :expires_in => options[:expires_in])
          end
        end

        define_method "#{method_name}_get_perma_cache" do
          PermaCache.cache.read(send("#{method_name}_perma_cache_key"))
        end

        define_method "#{method_name}_with_perma_cache" do
          send("#{method_name}_get_perma_cache") ||
          send("#{method_name}!")
        end

        alias_method_chain method_name, :perma_cache
      end
    end
  end
end

