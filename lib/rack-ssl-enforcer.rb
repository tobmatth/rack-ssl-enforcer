module Rack
  
  class SslEnforcer
    
    def initialize(app, options = {})
      @app     = app
      @options = options
    end
    
    def call(env)
      if ssl_request?(env)
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
      
  end
end