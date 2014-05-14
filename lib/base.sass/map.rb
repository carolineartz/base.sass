# Overrides official map functions to support nest keys.
module Sass::Script::Functions

  # Returns the value in a map associated with the given keys.
  #
  # Examples:
  # $map: (a: (b: (c: 1)));
  # map-get($map, a)       => (b: (c: 1))
  # map-get($map, a, b)    => (c: 1)
  # map-get($map, a, b, c) => 1
  def map_get(map, *keys)
    assert_type map, :Map
    assert_args_number(keys)

    hash, target = map.value, keys.pop

    keys.each do |key|
      # Each parent node must be a map
      unless hash[key].is_a? Sass::Script::Value::Map
        hash = {}
        break
      end
      hash = hash[key].value
    end

    hash[target] || null
  end

  # Returns a new map with keys removed.
  #
  # Examples:
  # $map: (a: (b: (c: 1)));
  # $map-remove($map, a)       => ()
  # $map-remove($map, a, b)    => (a: ())
  # $map-remove($map, a, b, c) => (a: (b: ()))
  def map_remove(map, *keys)
    return map unless map_has_key(map, *keys).to_bool

    target, hash = keys.pop, _dup(map, keys)
    hash.delete target

    while keys.size > 0
      target, _hash, hash = keys.pop, map(hash), _dup(map, keys)
      hash[target] = _hash
    end

    map(hash)
  end

  # Returns whether a map has a value associated with a given keys.
  #
  # Examples:
  # $map: (a: (b: (c: 1)));
  # $map-has-key($map, a)          => true
  # $map-has-key($map, a, b)       => true
  # $map-has-key($map, a, c)       => false
  # $map-has-key($map, a, b, c)    => true
  # $map-has-key($map, a, x, c)    => false
  # $map-has-key($map, a, b, c, d) => false
  def map_has_key(map, *keys)
    assert_type map, :Map
    assert_args_number(keys)

    hash = map.value

    keys.each do |key|
      # Each parent node must be a map
      return bool(false) unless hash.is_a?(Hash) && hash.key?(key)
      hash = hash[key].value
    end

    bool(true)
  end

  # Merges two maps together into a new map recursively.
  #
  # Examples:
  # $map1: (a: (b: (c: 1 2, d: foo, e: baz)));
  # $map2: (a: (b: (c: 3 4, d: bar)));
  # map-merge($map1, $map2)       => (a: (b: (c: 3 4,     d: bar)))
  # map-merge($map1, $map2, true) => (a: (b: (c: 1 2 3 4, d: bar, e: baz)))
  def map_merge(map1, map2, deep = bool(false))
    assert_type map1, :Map
    assert_type map2, :Map

    map1, map2 = map1.value.dup, map2.value
    return map(map1.merge(map2)) unless deep.to_bool

    map2.each do |k, v|
      orig = map1[k]
      map1[k] = _val(orig, v)
    end

    map(map1)
  end


  private

  def assert_args_number(keys)
    raise ArgumentError.new('wrong number of arguments (1 for 2+)') if keys.empty?
  end

  def _dup(map, keys)
    (keys.empty? ? map : map_get(map, *keys)).value.dup
  end

  def _val(oldVal, newVal)
    if oldVal.is_a?(Sass::Script::Value::Map) && newVal.is_a?(Sass::Script::Value::Map)
      map_merge(oldVal, newVal, bool(true))
    elsif oldVal.is_a?(Sass::Script::Value::List) && newVal.is_a?(Sass::Script::Value::List)
      join(oldVal, newVal)
    else
      newVal
    end
  end

end
