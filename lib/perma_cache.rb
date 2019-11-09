require 'active_support/all'

require "perma_cache/version"

module PermaCache
  class UndefinedCache < StandardError ; end

  def self.version=(v)
    @version = v
  end

  def self.version
    @version ||= 1
  end

  def self.cache=(c)
    @cache = c
  end

  def self.cache
    @cache ||= raise(UndefinedCache, "Please define a cache object: (PermaCache.cache = Rails.cache)")
  end

  def self.build_key_from_object(obj)
    # Don't want to add this to Object
    Array.new.tap do |arr|

      if obj.respond_to?(:cache_key)
        arr << obj.cache_key
      else
        arr << (obj.is_a?(Module) ? obj.name : obj.class.name)
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
    def perma_cache(original_name, options = {})
      options.symbolize_keys!
      valid_keys = [:expires_in, :obj, :version]
      raise "expected keys are #{valid_keys}" if (options.keys - valid_keys).present?
      class_eval do
        regex = /[\?\!]\Z/
        method_name   = original_name.to_s.gsub("!", "_exclamation").gsub("?", "_question")
        method_base   = original_name.to_s.gsub(regex,'')
        method_suffix = original_name.to_s.match(regex)

        was_rebuilt_inst_var = "@#{method_name}_was_rebuilt"

        define_method "#{method_name}_base_key" do
          key = []
          key << "perma_cache"
          key << "v#{PermaCache.version}"

          key << PermaCache.build_key_from_object(self)

          if options[:obj]
            key << PermaCache.build_key_from_object(send(options[:obj]))
          end

          if options[:version]
            key << "v#{options[:version]}"
          end

          key
        end

        define_method "#{method_name}_perma_cache_key" do
          [
            send("#{method_name}_base_key"),
            (send("#{method_name}_key") rescue nil),
            method_name
          ].flatten.compact.map(&:to_s).reject{|k| k.empty?}.join('/').gsub(' ','_')
        end

        define_method "#{method_name}!" do
          instance_variable_set(was_rebuilt_inst_var , true)
          send("#{method_base}_without_perma_cache#{method_suffix}").tap do |result|
            PermaCache.cache.write(send("#{method_name}_perma_cache_key"), result, :expires_in => options[:expires_in])
          end
        end

        define_method "#{method_name}_get_perma_cache" do
          PermaCache.cache.read(send("#{method_name}_perma_cache_key"))
        end

        with_perma_cache_method_name = "#{method_base}_with_perma_cache#{method_suffix}"
        define_method with_perma_cache_method_name do
          instance_variable_set(was_rebuilt_inst_var , false)

          send("#{method_name}_get_perma_cache") ||
            (
              instance_variable_set(was_rebuilt_inst_var , true) &&
              send("#{method_name}!")
          )
        end

        define_method "#{method_name}_was_rebuilt?" do
          instance_variable_get(was_rebuilt_inst_var ) == true
        end

        base_name = [method_base, method_suffix].join
        alias_method [[method_base, 'without', 'perma_cache'].compact.join('_'), method_suffix].join, base_name
        alias_method base_name, with_perma_cache_method_name
      end
    end
  end
end

