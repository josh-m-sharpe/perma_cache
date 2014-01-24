require 'test_helper'

class KlassOne
  include PermaCache

  def method1
    sleep 1
    1
  end
  perma_cache :method1

  def method2
    sleep 1
    2
  end
  perma_cache :method2, :obj => :other_klass
  def method2_key
    "more things"
  end

  def method3
    sleep 1
    3
  end
  perma_cache :method3, :version => 2, :expires_in => 5

  def other_klass
    KlassTwo.new
  end
end

class KlassTwo
  def cache_key
    "some_other_class/123"
  end
end

class KlassThree
  def id
    234
  end
end

class PermaCacheTest < Test::Unit::TestCase

  context "build_key_from_object" do
    context  "for a class" do
      context "That responds to cache_key" do
        should "have a correct key" do
          klass = KlassTwo
          assert klass.new.respond_to?(:cache_key)
          assert_equal ["some_other_class/123"], PermaCache.build_key_from_object(klass.new)
        end
      end
      context "that doesn't respond to cache_key" do
        should "have a correct key" do
          klass = KlassOne
          assert !klass.new.respond_to?(:cache_key)
          assert_equal ["KlassOne"], PermaCache.build_key_from_object(klass.new)
        end
      end
      context "that doesn't respond to cache key and responds to id" do
        should "have a correct key" do
          klass = KlassThree
          assert !klass.new.respond_to?(:cache_key)
          assert klass.new.respond_to?(:id)
          assert_equal ["KlassThree", 234], PermaCache.build_key_from_object(klass.new)
        end
      end
    end
  end

  context "calling cache" do
    context "without setting a cache source" do
      setup do
        PermaCache.send :remove_instance_variable, :@cache
      end
      should "raise" do
        assert_raises PermaCache::UndefinedCache do
          PermaCache.cache
        end
      end
    end
    context "after setting a cache source" do
      setup do
        PermaCache.cache = 123
      end
      should "return that cache source" do
        assert_equal 123, PermaCache.cache
      end
    end
  end

  context "KlassOne" do
    should "have some additional methods defined" do
      obj = KlassOne.new
      assert obj.respond_to?(:method1_perma_cache_key)
      assert obj.respond_to?(:method1!)
      assert obj.respond_to?(:method1_with_perma_cache)
    end

    should "calling #method1 should write and return the result if the cache is empty" do
      obj = KlassOne.new
      cache_obj = mock
      cache_obj.expects(:read).with(obj.method1_perma_cache_key).once.returns(nil)
      cache_obj.expects(:write).with(obj.method1_perma_cache_key, 1, :expires_in => nil).once
      PermaCache.cache = cache_obj
      obj.expects(:sleep).with(1).once
      assert_equal 1, obj.method1
    end

    should "calling #method1 should read the cache, but not write it, if the cache is present" do
      obj = KlassOne.new
      cache_obj = mock
      cache_obj.expects(:read).with(obj.method1_perma_cache_key).once.returns(123)
      cache_obj.expects(:write).never
      PermaCache.cache = cache_obj
      obj.expects(:sleep).never
      assert_equal 123, obj.method1
    end

    should "calling #method1! should write the cache, but not read from it" do
      obj = KlassOne.new
      cache_obj = mock
      cache_obj.expects(:read).never
      cache_obj.expects(:write).with(obj.method1_perma_cache_key, 1, :expires_in => nil).once
      PermaCache.cache = cache_obj
      obj.expects(:sleep).with(1).once
      assert_equal 1, obj.method1!
    end
  end
  context "version option" do
    should "add that key/value to the cache key" do
      assert_equal "perma_cache/v1/KlassOne/method3/v2", KlassOne.new.method3_perma_cache_key
    end
  end
  context "user defined keys" do
    should "should append themselves to the cache key" do
      assert_equal "perma_cache/v1/KlassOne/some_other_class/123/method2/more_things", KlassOne.new.method2_perma_cache_key
    end
  end
  context "setting expires_in" do
    should "pass the value through to #write" do
      obj = KlassOne.new
      cache_obj = mock
      cache_obj.expects(:read).with(obj.method3_perma_cache_key).returns(nil).once
      cache_obj.expects(:write).with(obj.method3_perma_cache_key, 3, :expires_in => 5).once
      obj.expects(:sleep).with(1).once
      PermaCache.cache = cache_obj
      obj.method3
    end
  end
end

