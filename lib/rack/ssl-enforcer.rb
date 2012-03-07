require 'rack/ssl-enforcer/constraint'

module Rack

  class SslEnforcer

    CONSTRAINTS_BY_TYPE = {
      :hosts   => [:only_hosts, :except_hosts],
      :path    => [:only, :except],
      :methods => [:only_methods, :except_methods]
    }

    # Warning: If you set the option force_secure_cookies to false, make sure that your cookies
    #  are encoded and that you understand the consequences (see documentation)
    def initialize(app, options={})
      default_options = {
        :redirect_to          => nil,
        :strict               => false,
        :mixed                => false,
        :hsts                 => nil,
        :http_port            => nil,
        :https_port           => nil,
        :force_secure_cookies => true
      }
      CONSTRAINTS_BY_TYPE.values.each { |constraint| default_options[constraint] = nil }

      @app, @options = app, default_options.merge(options)
    end

    def call(env)
      @request = Rack::Request.new(env)
      scheme = if enforce_ssl?
        'https'
      elsif enforce_non_ssl?
        'http'
      end

      if scheme && scheme != current_scheme
        location = replace_scheme(@request, scheme)
        body     = "<html><body>You are being <a href=\"#{location}\">redirected</a>.</body></html>"
        [301, { 'Content-Type' => 'text/html', 'Location' => location }, [body]]
      elsif ssl_request?
        status, headers, body = @app.call(env)
        flag_cookies_as_secure!(headers) if @options[:force_secure_cookies]
        set_hsts_headers!(headers) if @options[:hsts] && !@options[:strict]
        [status, headers, body]
      else
        @app.call(env)
      end
    end

  private

    def enforce_non_ssl?
      true if @options[:strict] || @options[:mixed] && !(@request.request_method == 'PUT' || @request.request_method == 'POST')
    end

    def ssl_request?
      current_scheme == 'https'
    end

    # Fixed in rack >= 1.3
    def current_scheme
      if @request.env['HTTPS'] == 'on'
        'https'
      elsif @request.env['HTTP_X_FORWARDED_PROTO']
        @request.env['HTTP_X_FORWARDED_PROTO'].split(',')[0]
      else
        @request.scheme
      end
    end

    def enforce_ssl_for?(keys)
      provided_keys = keys.select { |key| @options[key] }
      if provided_keys.empty?
        true
      else
        provided_keys.all? do |key|
          rules = [@options[key]].flatten.compact
          rules.send([:except_hosts, :except].include?(key) ? :all? : :any?) do |rule|
            SslEnforcerConstraint.new(key, rule, @request).matches?
          end
        end
      end
    end

    def enforce_ssl?
      CONSTRAINTS_BY_TYPE.inject(true) do |memo, (type, keys)|
        memo && enforce_ssl_for?(keys)
      end
    end

    def replace_scheme(req, scheme)
      if @options[:redirect_to]
        uri = URI.split(@options[:redirect_to])
        uri = uri[2] || uri[5]
      else
        uri = nil
      end
      host = uri || req.host
      port = port_for(scheme).to_s

      URI.parse("#{scheme}://#{host}:#{port}#{req.fullpath}").to_s
    end

    def port_for(scheme)
      if scheme == 'https'
        @options[:https_port] || 443
      else
        @options[:http_port] || 80
      end
    end

    # see http://en.wikipedia.org/wiki/HTTP_cookie#Cookie_theft_and_session_hijacking
    def flag_cookies_as_secure!(headers)
      if cookies = headers['Set-Cookie']
        # Support Rails 2.3 / Rack 1.1 arrays as headers
        unless cookies.is_a?(Array)
          cookies = cookies.split("\n")
        end

        headers['Set-Cookie'] = cookies.map do |cookie|
          cookie !~ / secure;/ ? "#{cookie}; secure" : cookie
        end.join("\n")
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
