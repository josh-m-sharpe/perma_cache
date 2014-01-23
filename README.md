# PermaCache

Provides a dsl to add pull-through caching to a given method while
also provding an interface to overwrite that cache when necessary.

Useful for expensive objects that you want to write-once on the backend
while still allowing your frontend to rebuild the object if the
cache clears for any reason

## Installation

Add this line to your application's Gemfile:

    gem 'perma_cache'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install perma_cache

## Usage

```
class SomeKlass
  include PermaCache
  def slow_method
    sleep 2
    1
  end
  perma_cache :slow_method
end
```

```
> Benchmark.measure{ puts SomeKlass.new.slow_method }.real
1
=> 2.003525972366333
> Benchmark.measure{ puts SomeKlass.new.slow_method }.real
1
=> 0.001032114028930664
> Benchmark.measure{ puts SomeKlass.new.slow_method! }.real
1
=> 2.0027248859405518
```

## Testing

Run tests with:
```
rake
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Run the test Suite
4. Commit your changes (`git commit -am 'Add some feature'`)
5. Push to the branch (`git push origin my-new-feature`)
6. Create new Pull Request

