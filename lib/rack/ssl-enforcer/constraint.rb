class SslEnforcerConstraint
  def initialize(name, rule, request)
    @name    = name
    @rule    = rule
    @request = request
  end

  def matches?
    if @rule.is_a?(String) && [:only, :except].include?(@name)
      result = tested_string[0, @rule.size].send(operator, @rule)
    else
      result = tested_string.send(operator, @rule)
    end
    
    negate_result? ? !result : result
  end

private
  
  def negate_result?
    @name.to_s =~ /except/
  end

  def operator
    @rule.is_a?(Regexp) ? "=~" : "=="
  end

  def tested_string
    case @name.to_s
    when /hosts/
      @request.host
    when /methods/
      @request.request_method
    else
      @request.path
    end
  end
end
