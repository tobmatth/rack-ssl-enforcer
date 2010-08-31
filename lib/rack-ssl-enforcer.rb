module Rack
  class SslEnforcer
    
    def initialize(app, options = {})
      @app, @options = app, options
    end
    
    def call(env)
      if enforce_ssl?(env)
        scheme = 'https' unless ssl_request?(env)
      elsif ssl_request?(env) && @options[:strict]
        scheme = 'http'
      end
      
      if scheme
        @options[:redirect_to] ||= Rack::Request.new(env).url
        @options[:redirect_to].gsub!(/^#{scheme == "https" ? 'http' : 'https'}:/, "#{scheme}:")
        @options[:message] ||= "You are being redirected to #{@options[:redirect_to]}."
        [301, { 'Location' => @options[:redirect_to] }, @options[:message]]
      else
        @app.call(env)
      end
    end
    
  private
    
    def ssl_request?(env)
      (env['HTTP_X_FORWARDED_PROTO'] || env['rack.url_scheme']) == 'https'
    end
    
    def enforce_ssl?(env)
      path = env['PATH_INFO']
      if @options[:only]
        rules = [@options[:only]].flatten
        rules.any? do |pattern|
          if pattern.is_a?(Regexp)
            path =~ pattern
          else
            path[0,pattern.length] == pattern
          end
        end
      else
        true
      end
    end
    
  end
end