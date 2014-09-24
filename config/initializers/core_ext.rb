class Float
  def roundf(precision = 2, zero = 2)
    val = round(precision)
    sprintf("%.#{zero}f", val)
  end
end

class Fixnum
  def roundf(precision = 2, zero = 2)
    self.to_f.roundf(precision, zero)
  end
  def empty?
    false
  end
end

class String
  def casecmp?(str)
    self.casecmp(str) == 0
  end

  def half_swap
    _str = self.clone
    len = _str.length / 2 - 1
    offset = _str.length / 2 + _str.length % 2
    0.upto(len).each do |i|
      _str[i], _str[offset + i] = _str[offset + i], _str[i]
    end
    _str
  end

  def get_params
    params_str = self.split("?")[1]
    return {} unless params_str
    params_str.split('&').inject({}) do |hash, str|
      arr = str.split('=')
      if arr[0] =~ /(\w*)\[(\w*)\]/
        hash.merge($1 => {$2 => arr[1]})
      else
        hash.merge(arr[0] => arr[1])
      end
    end
  end

  def valid_name
    self.gsub(/[^\w ]/, " ").squish
  end
end

class Hash
  def has_keys?(*keys)
    return false if keys.blank?
    keys.inject(true) {|result, k| result && has_key?(k) }
  end

  def to_uri
    uri = ''
    self.each_with_index do |arr, i|
      uri << "#{(i > 0) ? "&" : ""}#{arr[0]}=#{arr[1]}"
    end
    URI.escape(uri)
  end

  def extract(*keys)
    result = {}
    keys.flatten.each {|key| result[key] = self[key] }
    result
  end

  def mdelete(*keys)
    self.delete_if{|k, v| k.in?(keys.flatten)}
  end

  def fixed_hash
    g = {}
    self.each_pair do |k, v|
      g[k.to_s] = v.is_a?(Hash) ? v.fixed_hash : v.to_s
    end
    g
  end

  def in_hash(new_hash)
    return false unless ((s_keys = self.keys) & new_hash.keys) == s_keys
    use_hash = new_hash.extract s_keys
    res = self.inject(true) do |res, (k, v)|
      return unless res
      res = !v.is_a?(Hash) ? (v == use_hash[k]) : (v.in_hash(use_hash[k]))
    end
  end
end

class Range
  def dasherize
    if self.last == Float::INFINITY
      "#{self.begin}+"
    else
      "#{self.begin} - #{self.last}"
    end
  end
end

class NilClass
  def [](key)
    nil
  end
end

class ActiveSupport::TimeWithZone
  def to_local(long = true, zone = 'Beijing')
    self.utc.in_time_zone(zone).strftime("%F %#{long ? 'T' : 'R'}")
  end
end
