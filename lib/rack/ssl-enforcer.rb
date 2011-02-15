module Rack
  class SslEnforcer

    def initialize(app, options = {})
      @app, @options = app, options
    end

    def call(env)
      @req = Rack::Request.new(env)
      if enforce_ssl?(@req)
        scheme = 'https' unless ssl_request?(env)
      elsif ssl_request?(env) && enforcement_non_ssl?(env)
        scheme = 'http'
      end

      if scheme
        location = replace_scheme(@req, scheme).url
        body     = "<html><body>You are being <a href=\"#{location}\">redirected</a>.</body></html>"
        [301, { 'Content-Type' => 'text/html', 'Location' => location }, [body]]
      elsif ssl_request?(env)
        status, headers, body = @app.call(env)
        flag_cookies_as_secure!(headers)
        set_hsts_headers!(headers) if @options[:hsts] && !@options[:strict]
        [status, headers, body]
      else
        @app.call(env)
      end
    end

  private

    def enforcement_non_ssl?(env)
      true if @options[:strict] || @options[:mixed] && !(env['REQUEST_METHOD'] == 'PUT' || env['REQUEST_METHOD'] == 'POST')
    end

    def ssl_request?(env)
      scheme(env) == 'https'
    end

    # Fixed in rack >= 1.3
    def scheme(env)
      if env['HTTPS'] == 'on'
        'https'
      elsif env['HTTP_X_FORWARDED_PROTO']
        env['HTTP_X_FORWARDED_PROTO'].split(',')[0]
      else
        env['rack.url_scheme']
      end
    end

    def matches?(key, pattern, req)
      if pattern.is_a?(Regexp)
        case key
        when :only
          req.path =~ pattern
        when :except
          req.path !~ pattern
        when :only_hosts
          req.host =~ pattern
        when :except_hosts
          req.host !~ pattern
        end
      else
        case key
        when :only
          req.path[0,pattern.length] == pattern
        when :except
          req.path[0,pattern.length] != pattern
        when :only_hosts
          req.host == pattern
        when :except_hosts
          req.host != pattern
        end
      end
    end

    def enforce_ssl_for?(keys, req)
      if keys.any? {|option| @options.key?(option)}
        keys.any? do |key|
          rules = [@options[key]].flatten.compact
          rules.any? do |pattern|
            matches?(key, pattern, req)
          end
        end
      else
        false
      end
    end

    def enforce_ssl?(req)
      path_keys = [:only, :except]
      hosts_keys = [:only_hosts, :except_hosts]
      if hosts_keys.any? {|option| @options.key?(option)}
        if enforce_ssl_for?(hosts_keys, req)
          if path_keys.any? {|option| @options.key?(option)}
            enforce_ssl_for?(path_keys, req)
          else
            true
          end
        else
          false
        end
      elsif path_keys.any? {|option| @options.key?(option)}
        enforce_ssl_for?(path_keys, req)
      else
        true
      end
    end

    def replace_scheme(req, scheme)
      if @options[:redirect_to]
        uri = URI.split(@options[:redirect_to])
        uri = uri[2] || uri[5]
      else
        uri = nil
      end
      Rack::Request.new(req.env.merge(
        'rack.url_scheme' => scheme,
        'HTTP_X_FORWARDED_PROTO' => scheme,
        'HTTP_X_FORWARDED_PORT' => port_for(scheme).to_s,
        'SERVER_PORT' => port_for(scheme).to_s
      ).merge(uri ? {'HTTP_HOST' => uri} : {}))
    end

    def port_for(scheme)
      scheme == 'https' ? 443 : 80
    end

    # see http://en.wikipedia.org/wiki/HTTP_cookie#Cookie_hijacking
    def flag_cookies_as_secure!(headers)
      if cookies = headers['Set-Cookie']
        headers['Set-Cookie'] = cookies.split("\n").map { |cookie|
          if cookie !~ / secure;/
            "#{cookie}; secure"
          else
            cookie
          end
        }.join("\n")
      end
    end

    # see http://en.wikipedia.org/wiki/Strict_Transport_Security
    def set_hsts_headers!(headers)
      opts = { :expires => 31536000, :subdomains => true }
      opts.merge!(@options[:hsts]) if @options[:hsts].is_a? Hash
      value  = "max-age=#{opts[:expires]}"
      value += "; includeSubDomains" if opts[:subdomains]
      headers.merge!({ 'Strict-Transport-Security' => value })
    end

  end
end
