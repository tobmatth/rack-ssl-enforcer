module Rack
  
  class SslEnforcer
    
    def initialize(app, *args)
      @app = app
      case args[0].class.to_s
      when 'Hash'
        @options = args[0]
      when 'Regexp', 'String', 'Array'
        @rules = [args[0]].flatten
        @options = args[1]
      end
      @options ||= {}
    end
    
    def call(env)
      if ssl_request?(env) || !enforce_ssl?(env)
        @app.call(env)
      else
        @options[:redirect_to] ||= Rack::Request.new(env).url
        @options[:redirect_to].gsub!(/^http:/, 'https:')
        @options[:message] ||= "You are beeing redirected to #{@options[:redirect_to]}."
        [301, { 'Location' => @options[:redirect_to] }, @options[:message]]
      end
    end
    
    private
      
      def ssl_request?(env)
        (env['HTTP_X_FORWARDED_PROTO'] || env['rack.url_scheme']) == 'https'
      end
      
      def enforce_ssl?(env)
        path = env['PATH_INFO']
        if @rules
          @rules.any? do |pattern|
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