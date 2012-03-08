class SslEnforcerConstraint
  def initialize(name, rule, request)
    @name    = name
    @rule    = rule
    @request = request
  end

  def matches?
    if @rule.is_a?(String) && [:only, :except].include?(@name)
      tested_string[0, @rule.size].send(operator, @rule)
    else
      tested_string.send(operator, @rule)
    end
  end

private

  def operator
    "#{operator_prefix}#{operator_suffix}"
  end

  def operator_prefix
    case @name
    when /only/
      "="
    when /except/
      "!"
    end
  end

  def operator_suffix
    @rule.is_a?(Regexp) ? "~" : "="
  end

  def tested_string
    case @name
    when /hosts/
      @request.host
    when /methods/
      @request.request_method
    else
      @request.path
    end
  end
end
