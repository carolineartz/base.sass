module Sass::Script::Functions
  # https://github.com/ai/autoprefixer#browsers
  # https://github.com/ai/autoprefixer/blob/master/lib/browsers.coffee#L45

  def parse_rules(*rules)
    @browsers ||= CanIUse.instance.browsers_data
    rules = rules.map { |r| sass_to_ruby(r) }.flatten.uniq

    rules.map! do |rule|
      rule = rule.to_s.downcase

      # match `last 1 version`
      if rule =~ /^last (\d+) versions?$/
        last_versions_parser($1)

      # match `last 3 chrome versions`
      elsif rule =~ /^last (\d+) (\w+) versions?$/
        last_browser_versions_parser($1, $2)

      # match `ie > 9`
      elsif rule =~ /^(\w+) (>=?) ([\d\.]+)$/
        newer_then_parser($1, $2, $3)

      # match `ios 7`
      elsif rule =~ /^(\w+) ([\d\.]+)$/
        direct_parser($1, $2)

      else
        raise Sass::SyntaxError, "Unknown rule: `#{rule}`"
      end
    end

    ruby_to_sass(rules.inject({}) { |memo, browsers|
      browsers.each do |k, v|
        memo[k] ||= []
        memo[k] += v
        memo[k].uniq!
        memo[k].sort!
      end
      memo
    })
  end

  def browser_versions(name)
    @browsers ||= CanIUse.instance.browsers_data
    assert_browser_name(name.value)

    browser = @browsers[name.value]
    versions = browser['versions']
    versions += browser['future'] if browser.key? 'future'

    ruby_to_sass(versions)
  end


  protected

  def assert_browser_name(name)
    unless @browsers.key? name
      raise Sass::SyntaxError, "Unknown browser name: #{name}\nAll valid browsers are #{@browsers.keys}"
    end
  end

  def assert_browser_version(name, version)
    unless @browsers[name]['versions'].include? version
      raise Sass::SyntaxError, "Unknown version of #{name}: #{version}\nYou can find all valid versions according to `browser-versions(#{name})`"
    end
  end

  # def browser_prefix(browser)
  #   assert_type browser, :String
  # end

  # def browser_prefixes(browsers)
  #   assert_type browsers, :List
  # end


  private

  def last_versions_parser(num)
    @browsers.inject({}) do |memo, (k, v)|
      memo[k] = v['versions'].last(num.to_i)
      memo
    end
  end

  def last_browser_versions_parser(num, browser)
    assert_browser_name(browser)
    Hash[browser, @browsers[browser]['versions'].last(num.to_i)]
  end

  def newer_then_parser(browser, sign, version)
    assert_browser_name(browser)

    versions = @browsers[browser]['versions']
    Hash[browser,
      case sign
      when '>='
        versions.select { |n| n >= version.to_f }
      when '>'
        versions.select { |n| n > version.to_f }
      end
    ]
  end

  def direct_parser(browser, version)
    assert_browser_name(browser)

    version = version.include?('.') ? version.to_f : version.to_i
    assert_browser_version(browser, version)

    Hash[browser, [version]]
  end
end