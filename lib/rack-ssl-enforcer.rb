module Rack

  class SslEnforcer

    def initialize(app, options = {})
      @app = app
      @options = options
    end
 
    def call(env)
      @options[:redirect_to] ||= Rack::Request.new(env).url
      @options[:redirect_to].gsub!(/^http:/,'https:')
      @options[:message] ||= "You are beeing redirected to #{@options[:redirect_to]}."
      ssl_request?(env) ? @app.call(env) : [301, {'Location' => @options[:redirect_to]}, @options[:message]]
    end
    
    
    private
      
      def ssl_request?(env)
        (env['HTTP_X_FORWARDED_PROTO'] || env['rack.url_scheme']) == 'https'
      end
 
  end
end
