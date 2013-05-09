require 'rack/ssl-enforcer/constraint'

module Rack

  class SslEnforcer

    CONSTRAINTS_BY_TYPE = {
      :hosts              => [:only_hosts, :except_hosts],
      :path               => [:only, :except],
      :methods            => [:only_methods, :except_methods],
      :methods_with_paths => [:only_methods_with_paths, :except_methods_with_paths],
      :environments       => [:only_environments, :except_environments]
    }

    # Warning: If you set the option force_secure_cookies to false, make sure that your cookies
    # are encoded and that you understand the consequences (see documentation)
    def initialize(app, options={})
      default_options = {
        :redirect_to          => nil,
        :redirect_code        => nil,
        :strict               => false,
        :mixed                => false,
        :hsts                 => nil,
        :http_port            => nil,
        :https_port           => nil,
        :force_secure_cookies => true
      }
      CONSTRAINTS_BY_TYPE.values.each do |constraints|
        constraints.each { |constraint| default_options[constraint] = nil }
      end

      @app, @options = app, default_options.merge(options)
    end

    def call(env)
      @request = Rack::Request.new(env)

      return @app.call(env) if ignore?

      @scheme = if enforce_ssl?
        'https'
      elsif enforce_non_ssl?
        'http'
      end

      if redirect_required?
        modify_location_and_redirect
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

    def redirect_required?
      scheme_mismatch? || host_mismatch?
    end

    def ignore?
      if @options[:ignore]
        rules = [@options[:ignore]].flatten.compact
        rules.any? do |rule|
          SslEnforcerConstraint.new(:ignore, rule, @request).matches?
        end
      else
        false
      end
    end

    def scheme_mismatch?
      @scheme && @scheme != current_scheme
    end

    def host_mismatch?
      destination_host && destination_host != @request.host
    end

    def modify_location_and_redirect
      location = "#{current_scheme}://#{@request.host}#{@request.fullpath}"
      location = replace_scheme(location, @scheme)
      location = replace_host(location, @options[:redirect_to])
      redirect_to(location)
    end

    def redirect_to(location)
      body = "<html><body>You are being <a href=\"#{location}\">redirected</a>.</body></html>"
      [@options[:redirect_code] || 301, { 'Content-Type' => 'text/html', 'Location' => location }, [body]]
    end

    def ssl_request?
      current_scheme == 'https'
    end

    def destination_host
      if @options[:redirect_to]
        host_parts = URI.split(@options[:redirect_to])
        host_parts[2] || host_parts[5]
      end
    end

    # Fixed in rack >= 1.3
    def current_scheme
      if @request.env['HTTPS'] == 'on' || @request.env['HTTP_X_SSL_REQUEST'] == 'on'
        'https'
      elsif @request.env['HTTP_X_FORWARDED_PROTO']
        @request.env['HTTP_X_FORWARDED_PROTO'].split(',')[0]
      else
        @request.scheme
      end
    end

    def enforce_ssl_for?(constraints)

      # Need to divide constraints into the following groups and combine the results as:
      # (methodpath_combo_matches || methodpath_discrete_matches) && other_discrete_matches
      methodpath_combo_constraints = constraints.select do |constraint|
        constraint.to_s =~ /methods_with_paths$/ ? true : false
      end
      methodpath_discrete_constraints = constraints.select do |constraint|
        constraint.to_s =~ /(only$|except$|methods$)/ ? true : false
      end
      other_discrete_constraints = constraints.reject do |constraint|
        constraint.to_s =~ /(only$|except$|methods)/ ? true : false
      end

      # For methodpath_combo_constraints, match method and path rules separately, then combine the results.
      methodpath_combo_matches = methodpath_combo_constraints.any? do |constraint|
        constraint_type = constraint.to_s[0, constraint.to_s.index('_') || constraint.to_s.length]

        @options[constraint].send(constraint_type == 'except' ? :all? : :any?) do |method_rules, path_rules|

          method_rules = [method_rules].flatten.compact
          method_constraint = "#{constraint_type}_methods".to_sym
          method_matches = method_rules.send(constraint_type == 'except' ? :all? : :any?) do |method_rule|
            SslEnforcerConstraint.new(method_constraint, method_rule, @request).matches?
          end

          path_rules = [path_rules].flatten.compact
          path_constraint = constraint_type.to_sym
          path_matches = path_rules.send(constraint_type == 'except' ? :all? : :any?) do |path_rule|
            SslEnforcerConstraint.new(path_constraint, path_rule, @request).matches?
          end

          constraint_type == 'except' ? method_matches || path_matches : method_matches && path_matches
        end
      end

      # Use the same logic for both methodpath_discrete_constraints and other_discrete_constraints.
      matches = []
      [methodpath_discrete_constraints, other_discrete_constraints].each do |discrete_constraints|
        matches << discrete_constraints.all? do |constraint|
          constraint_type = constraint.to_s[0, constraint.to_s.index('_') || constraint.to_s.length]

          rules = [@options[constraint]].flatten.compact
          rules.send(constraint_type == 'except' ? :all? : :any?) do |rule|
            SslEnforcerConstraint.new(constraint, rule, @request).matches?
          end
        end
      end
      methodpath_discrete_matches, other_discrete_matches = matches

      # Bring it all together.
      if methodpath_combo_constraints.empty?
        methodpath_discrete_matches && other_discrete_matches
      elsif methodpath_discrete_constraints.empty?
        methodpath_combo_matches && other_discrete_matches
      else
        (methodpath_combo_matches || methodpath_discrete_matches) && other_discrete_matches
      end
    end

    def enforce_non_ssl?
      @options[:strict] || @options[:mixed] && !(@request.request_method == 'PUT' || @request.request_method == 'POST')
    end

    def enforce_ssl?
      all_constraints = CONSTRAINTS_BY_TYPE.values.flatten
      provided_constraints = all_constraints.select { |constraint| @options[constraint] }
      if provided_constraints.empty?
        true
      else
        enforce_ssl_for?(provided_constraints)
      end
    end

    def replace_scheme(uri, scheme)
      return uri if not scheme_mismatch?

      port = adjust_port_to(scheme)
      uri_parts = URI.split(uri)
      uri_parts[3] = port unless port.nil?
      uri_parts[0] = scheme
      URI::HTTP.new(*uri_parts).to_s
    end

    def replace_host(uri, host)
      return uri unless host_mismatch?

      host_parts = URI.split(host)
      new_host = host_parts[2] || host_parts[5]
      uri_parts = URI.split(uri)
      uri_parts[2] = new_host
      URI::HTTPS.new(*uri_parts).to_s
    end

    def adjust_port_to(scheme)
      if scheme == 'https'
        @options[:https_port] if @options[:https_port] && @options[:https_port] != URI::HTTPS.default_port
      elsif scheme == 'http'
        @options[:http_port] if @options[:http_port] && @options[:http_port] != URI::HTTP.default_port
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
          cookie !~ /(^|;\s)secure($|;)/ ? "#{cookie}; secure" : cookie
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
