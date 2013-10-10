class SslEnforcerConstraint
  def initialize(name, rule, request)
    @name    = name
    @rule    = rule
    @request = request
  end

  def matches?
    if @rule.is_a?(String)
      result = [@rule, "#{@rule}/"].include?(tested_string)
    else
      result = tested_string =~ @rule
    end

    negate_result? ? !result : result
  end

  private

  def negate_result?
    @name.to_s =~ /except/
  end

  def tested_string
    case @name.to_s
    when /hosts/
      @request.host
    when /methods/
      @request.request_method
    when /environments/
      ENV["RACK_ENV"] || ENV["RAILS_ENV"] || ENV["ENV"]
    when /agents/
      @request.user_agent
    else
      @request.path
    end
  end
end
