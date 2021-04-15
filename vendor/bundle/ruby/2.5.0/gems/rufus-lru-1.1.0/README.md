
# rufus-lru

[![Build Status](https://secure.travis-ci.org/jmettraux/rufus-lru.svg)](http://travis-ci.org/jmettraux/rufus-lru)
[![Gem Version](https://badge.fury.io/rb/rufus-lru.svg)](http://badge.fury.io/rb/rufus-lru)

LruHash class, a Hash with a max size, controlled by a LRU mechanism.


## getting it

```
gem install rufus-lru
```

or better, simply add to your ```Gemfile```

```
gem 'rufus-lru'
```


## usage

It's a regular hash, but you have to set a maxsize at instantiation.

Once the maxsize is reached, the hash will discard the element that was the
least recently used (hence LRU).

```ruby
require 'rufus-lru'

h = Rufus::Lru::Hash.new(3)

5.times { |i| h[i] = "a" * i }

puts h.inspect # >> {2=>"aa", 3=>"aaa", 4=>"aaaa"}

h[:newer] = 'b'

puts h.inspect # >> {:newer=>"b", 3=>"aaa", 4=>"aaaa"}
```

Rufus::Lru::Hash isn't thread-safe, if you need something that is, use Rufus::Lru::SynchronizedHash

```ruby
require 'rufus-lru'

h = Rufus::Lru::SynchronizedHash.new(3)

# ...
```

It's possible to squeeze LruHash manually:

```ruby
h = Rufus::Lru::Hash.new(33, :auto_squeeze => false)
  # or
#h = Rufus::Lru::Hash.new(33)
#h.auto_squeeze = false

# ... values keep accumulating ...

# when a squeeze is needed...
h.squeeze!
```

LruHash accepts on initialization a ```:on_removal``` option. It can be set to a Symbol, which is then used as the method name to call on the value just removed:

```ruby
require 'rufus-lru'

class ObjectWithDestructor; def clear; puts 'Destructor called'; end; end

h = LruHash.new(1, :on_removal => :clear)

h[:one] = ObjectWithDestructor.new
h[:two] = nil # :one is being removed >> "Destructor called"
```

Or it can be set to a lambda:

```ruby
require 'rufus-lru'

seen = []
h = Rufus::Lru::Hash.new(
  1,
  :on_removal => lambda { |val| seen << val.object_id })

h[:one] = 'abc'
h[:two] = 'xyz'

# seen ends up with the object_id of the 'abc' String instance...
```

The value of ```on_removal``` can be set later on.

```ruby
h.on_removal = :destroy
h.on_removal = lambda { |val| bodycount += 1 if val.is_a?(Martian) }
```

`auto_squeeze` and `on_removal` were originally contributed by Gleb Kuzmenko.


## dependencies

None.


## mailing list

On the rufus-ruby list:

http://groups.google.com/group/rufus-ruby


## issue tracker

http://github.com/jmettraux/rufus-lru/issues


## irc

irc.freenode.net #ruote


## source

http://github.com/jmettraux/rufus-lru

```
git clone git://github.com/jmettraux/rufus-lru.git
```


## author

John Mettraux, jmettraux@gmail.com, http://lambda.io/jmettraux


## contributors and help

see [CREDITS.txt](CREDITS.txt)


## license

MIT

