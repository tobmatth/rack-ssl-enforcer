require 'helper'

class TestRackSslEnforcer < Test::Unit::TestCase

  context 'no options' do
    setup { mock_app }

    should 'redirect to HTTPS and keep params' do
      get 'http://www.example.org/admin?token=33'
      assert_equal 301, last_response.status
      assert_equal 'https://www.example.org/admin?token=33', last_response.location
    end

    # heroku / etc do proxied SSL
    should 'respect X-Forwarded-Proto header for proxied SSL' do
      get 'http://www.example.org/', {}, { 'HTTP_X_FORWARDED_PROTO' => 'http', 'rack.url_scheme' => 'http' }
      assert_equal 301, last_response.status
      assert_equal 'https://www.example.org/', last_response.location
    end

    should 'not redirect SSL requests' do
      get 'https://www.example.org/'
      assert_equal 200, last_response.status
      assert_equal 'Hello world!', last_response.body
    end

    should 'not redirect SSL requests and respect X-Forwarded-Proto header for proxied SSL' do
      get 'http://www.example.org/', {}, { 'HTTP_X_FORWARDED_PROTO' => 'https', 'rack.url_scheme' => 'http' }
      assert_equal 200, last_response.status
      assert_equal 'Hello world!', last_response.body
    end

    should 'use default HTTPS port (443) when redirecting non-standard HTTP port to HTTPS' do
      get 'http://example.org:81/', {}, { 'rack.url_scheme' => 'http' }
      assert_equal 301, last_response.status
      assert_equal 'https://example.org/', last_response.location
    end

    should 'secure cookies' do
      get 'https://www.example.org/'
      assert_equal ["id=1; path=/; secure", "token=abc; path=/; secure; HttpOnly"], last_response.headers['Set-Cookie'].split("\n")
    end

    should 'not set default HSTS headers to SSL requests' do
      get 'https://www.example.org/'
      assert !last_response.headers["Strict-Transport-Security"]
    end

    should 'not set hsts headers to non-SSL requests' do
      get 'http://www.example.org/'
      assert !last_response.headers["Strict-Transport-Security"]
    end
  end

  context 'With Rails 2.3 / Rack 1.1-style Array-based cookies' do
    setup do
      main_app = lambda { |env|
        request = Rack::Request.new(env)
        headers = {'Content-Type' => "text/html"}
        headers['Set-Cookie'] = ["id=1; path=/", "token=abc; path=/; HttpOnly"]
        [200, headers, ['Hello world!']]
      }

      builder = Rack::Builder.new
      builder.use Rack::SslEnforcer
      builder.run main_app
      @app = builder.to_app
    end

    should 'secure cookies' do
      get 'https://www.example.org/'
      assert_equal ["id=1; path=/; secure", "token=abc; path=/; HttpOnly; secure"], last_response.headers['Set-Cookie'].split("\n")
    end
  end

  context ':http_port' do
    setup { mock_app :http_port => 8080, :only => [], :strict => true }

    should 'redirect to HTTP with custom port' do
      get 'https://www.example.org/'
      assert_equal 301, last_response.status
      assert_equal 'http://www.example.org:8080/', last_response.location
    end
  end

  context ':https_port' do
    setup { mock_app :https_port => 9443 }

    should 'redirect to HTTPS with custom port' do
      get 'http://www.example.org/'
      assert_equal 301, last_response.status
      assert_equal 'https://www.example.org:9443/', last_response.location
    end
  end

  context ':redirect_to' do
    setup { mock_app :redirect_to => 'https://www.google.com' }

    should 'redirect to HTTPS and keep params' do
      get 'http://www.example.org/admin?token=33'
      assert_equal 301, last_response.status
      assert_equal 'https://www.google.com/admin?token=33', last_response.location
    end

    should 'redirect to HTTPS and append scheme automatically' do
      mock_app :redirect_to => 'www.google.com'

      get 'http://www.example.org/'
      assert_equal 301, last_response.status
      assert_equal 'https://www.google.com/', last_response.location
    end

    should 'redirect SSL requests if hosts do not match' do
      get 'https://www.example.org/'
      assert_equal 301, last_response.status
      assert_equal 'https://www.google.com/', last_response.location
    end

    should 'not redirect SSL requests if hosts match' do
      get 'https://www.google.com'
      assert_equal 200, last_response.status
      assert_equal 'Hello world!', last_response.body
    end
  end

  context ":before_redirect" do
    def self.startup
      @before_redirect_called = false
    end
    setup { mock_app :redirect_to => 'https://www.google.com', :before_redirect => Proc.new {
      @before_redirect_called = true
    }}
    should "call before_direct when redirecting" do
      get 'http://www.google.com/'
      assert @before_redirect_called, "before_redirect was not called"
    end
    should "not call before_direct when not redirecting" do
      get 'https://www.google.com/'
      refute @before_redirect_called, "before_redirect was called"
    end
  end

  context ':redirect_code' do
    setup { mock_app :redirect_code => 302 }

    should 'redirect to HTTPS and keep params' do
      get 'http://www.example.org/admin/account'
      assert_equal 302, last_response.status
      assert_equal 'https://www.example.org/admin/account', last_response.location
    end
  end

  context ':only (Regex)' do
    setup { mock_app :only => /^\/admin/ }

    should 'redirect to HTTPS for /admin' do
      get 'http://www.example.org/admin/account'
      assert_equal 301, last_response.status
      assert_equal 'https://www.example.org/admin/account', last_response.location
    end

    should 'not redirect for other paths' do
      get 'http://www.example.org/foo'
      assert_equal 200, last_response.status
      assert_equal 'Hello world!', last_response.body
    end
  end

  context ':only (String)' do
    setup { mock_app :only => "/account" }

    should 'redirect to HTTPS for /account' do
      get 'http://www.example.org/account'
      assert_equal 301, last_response.status
      assert_equal 'https://www.example.org/account', last_response.location
    end

    should 'redirect to HTTPS for /account/public' do
      get 'http://www.example.org/account/public'
      assert_equal 301, last_response.status
      assert_equal 'https://www.example.org/account/public', last_response.location
    end

    should 'not redirect SSL requests for /account' do
      get 'https://www.example.org/account'
      assert_equal 200, last_response.status
      assert_equal 'Hello world!', last_response.body
    end

    should 'not redirect for /foo' do
      get 'http://www.example.org/foo'
      assert_equal 200, last_response.status
      assert_equal 'Hello world!', last_response.body
    end
  end

  context ':only (Array)' do
    setup { mock_app :only => [/\.xml$/, "/login"] }

    should 'redirect to HTTPS for /login' do
      get 'http://www.example.org/login'
      assert_equal 301, last_response.status
      assert_equal 'https://www.example.org/login', last_response.location
    end

    should 'redirect to HTTPS for /admin path' do
      get 'http://www.example.org/users.xml'
      assert_equal 301, last_response.status
      assert_equal 'https://www.example.org/users.xml', last_response.location
    end

    should 'not redirect for /foo' do
      get 'http://www.example.org/foo/'
      assert_equal 200, last_response.status
      assert_equal 'Hello world!', last_response.body
    end
  end

  context ':only (Array) & :strict == true' do
    setup { mock_app :only => [/\.xml$/, "/login"], :strict => true }

    should 'redirect to HTTP for /foo' do
      get 'https://www.example.org/foo'
      assert_equal 301, last_response.status
      assert_equal 'http://www.example.org/foo', last_response.location
    end

    should 'not redirect for /login' do
      get 'https://www.example.org/login'
      assert_equal 200, last_response.status
      assert_equal 'Hello world!', last_response.body
    end
  end

  context ':except (Regex)' do
    setup { mock_app :except => /^\/foo/ }

    should 'redirect to HTTPS for /admin' do
      get 'http://www.example.org/admin'
      assert_equal 301, last_response.status
      assert_equal 'https://www.example.org/admin', last_response.location
    end

    should 'not redirect for /foo' do
      get 'http://www.example.org/foo'
      assert_equal 200, last_response.status
      assert_equal 'Hello world!', last_response.body
    end
  end

  context ':except (String)' do
    setup { mock_app :except => "/foo" }

    should 'redirect to HTTPS for /login' do
      get 'http://www.example.org/login'
      assert_equal 301, last_response.status
      assert_equal 'https://www.example.org/login', last_response.location
    end

    should 'not redirect for /foo' do
      get 'http://www.example.org/foo/'
      assert_equal 200, last_response.status
      assert_equal 'Hello world!', last_response.body
    end
  end

  context ':except (Array)' do
    setup { mock_app :except => [/^\/foo/, "/bar"] }

    should 'redirect to HTTPS for /admin' do
      get 'http://www.example.org/admin'
      assert_equal 301, last_response.status
      assert_equal 'https://www.example.org/admin', last_response.location
    end

    should 'not redirect for /foo' do
      get 'http://www.example.org/foo'
      assert_equal 200, last_response.status
      assert_equal 'Hello world!', last_response.body
    end

    should 'not redirect for /bar' do
      get 'http://www.example.org/bar'
      assert_equal 200, last_response.status
      assert_equal 'Hello world!', last_response.body
    end
  end

  context ':except & :strict == true' do
    setup { mock_app :except => "/foo", :strict => true }

    should 'redirect to HTTP for /foo' do
      get 'https://www.example.org/foo/'
      assert_equal 301, last_response.status
      assert_equal 'http://www.example.org/foo/', last_response.location
    end

    should 'not redirect for /login' do
      get 'https://www.example.org/login'
      assert_equal 200, last_response.status
      assert_equal 'Hello world!', last_response.body
    end
  end

  context ':ignore (Regex)' do
    setup { mock_app :ignore => /^\/foo/}

    should 'not redirect for http' do
      get 'http://www.example.org/foo'
      assert_equal 200, last_response.status
      assert_equal 'Hello world!', last_response.body
    end

    should 'not redirect for https' do
      get 'https://www.example.org/foo'
      assert_equal 200, last_response.status
      assert_equal 'Hello world!', last_response.body
    end
  end

  context ':ignore (String)' do
    setup { mock_app :ignore => '/foo'}

    should 'not redirect for http' do
      get 'http://www.example.org/foo'
      assert_equal 200, last_response.status
      assert_equal 'Hello world!', last_response.body
    end

    should 'not redirect for https' do
      get 'https://www.example.org/foo'
      assert_equal 200, last_response.status
      assert_equal 'Hello world!', last_response.body
    end
  end

  context ':ignore (Nested String)' do
    setup { mock_app :only => '/foo', :ignore => '/foo/bar'}

    should 'not redirect for nested url' do
      get 'http://www.example.org/foo/bar'
      assert_equal 200, last_response.status
      assert_equal 'Hello world!', last_response.body
    end
  end

  context ':ignore (Array)' do
    setup { mock_app :ignore => [/^\/foo/,'/bar']}

    should 'not redirect for http for /foo' do
      get 'http://www.example.org/foo'
      assert_equal 200, last_response.status
      assert_equal 'Hello world!', last_response.body
    end

    should 'not redirect for https for /foo' do
      get 'https://www.example.org/foo'
      assert_equal 200, last_response.status
      assert_equal 'Hello world!', last_response.body
    end

    should 'not redirect for http for /bar' do
      get 'http://www.example.org/bar'
      assert_equal 200, last_response.status
      assert_equal 'Hello world!', last_response.body
    end

    should 'not redirect for https for /bar' do
      get 'https://www.example.org/bar'
      assert_equal 200, last_response.status
      assert_equal 'Hello world!', last_response.body
    end
  end

  context ':only_hosts (Regex)' do
    setup { mock_app :only_hosts => /[www|api]\.example\.co\.uk$/ }

    should 'redirect to HTTPS for www.example.co.uk' do
      get 'http://www.example.co.uk'
      assert_equal 301, last_response.status
      assert_equal 'https://www.example.co.uk/', last_response.location
    end

    should 'redirect to HTTPS for api.example.co.uk' do
      get 'http://api.example.co.uk'
      assert_equal 301, last_response.status
      assert_equal 'https://api.example.co.uk/', last_response.location
    end

    should 'not redirect for goo.example.co.uk' do
      get 'http://goo.example.co.uk'
      assert_equal 200, last_response.status
      assert_equal 'Hello world!', last_response.body
    end

    should 'not redirect for goo.example.co.uk for goo.example.co.uk' do
      get 'http://teambox.example.co.uk'
      assert_equal 200, last_response.status
      assert_equal 'Hello world!', last_response.body
    end
  end

  context ':only_hosts (String)' do
    setup { mock_app :only_hosts => "example.org" }

    should 'redirect to HTTPS for example.org' do
      get 'http://example.org'
      assert_equal 301, last_response.status
      assert_equal 'https://example.org/', last_response.location
    end

    should 'not redirect for www.example.org' do
      get 'http://www.example.org'
      assert_equal 200, last_response.status
      assert_equal 'Hello world!', last_response.body
    end

    should 'not redirect for example.com' do
      get 'http://www.example.com'
      assert_equal 200, last_response.status
      assert_equal 'Hello world!', last_response.body
    end
  end

  context ':only_hosts (Array)' do
    setup { mock_app :only_hosts => [/[www|api]\.example\.org$/, "example.com"] }

    should 'redirect to HTTPS for www.example.org' do
      get 'http://www.example.org'
      assert_equal 301, last_response.status
      assert_equal 'https://www.example.org/', last_response.location
    end

    should 'redirect to HTTPS for api.example.org' do
      get 'http://api.example.org'
      assert_equal 301, last_response.status
      assert_equal 'https://api.example.org/', last_response.location
    end

    should 'not redirect for goo.example.com' do
      get 'http://goo.example.com'
      assert_equal 200, last_response.status
      assert_equal 'Hello world!', last_response.body
    end

    should 'not redirect for example.org' do
      get 'http://example.org'
      assert_equal 200, last_response.status
      assert_equal 'Hello world!', last_response.body
    end

    should 'not redirect for goo.example.org' do
      get 'http://goo.example.org'
      assert_equal 200, last_response.status
      assert_equal 'Hello world!', last_response.body
    end
  end

  context ':except_hosts (Regex)' do
    setup { mock_app :except_hosts => /[www|api]\.example\.co\.uk$/ }

    should 'redirect to HTTPS for goo.example.co.uk' do
      get 'http://goo.example.co.uk'
      assert_equal 301, last_response.status
      assert_equal 'https://goo.example.co.uk/', last_response.location
    end

    should 'not redirect for www.example.co.uk' do
      get 'http://api.example.co.uk'
      assert_equal 200, last_response.status
      assert_equal 'Hello world!', last_response.body
    end

    should 'not redirect for api.example.co.uk' do
      get 'http://api.example.co.uk'
      assert_equal 200, last_response.status
      assert_equal 'Hello world!', last_response.body
    end
  end

  context ':except_hosts (String)' do
    setup { mock_app :except_hosts => "www.example.org" }

    should 'redirect to HTTPS for api.example.org' do
      get 'http://api.example.org'
      assert_equal 301, last_response.status
      assert_equal 'https://api.example.org/', last_response.location
    end

    should 'not redirect for www.example.org' do
      get 'http://www.example.org'
      assert_equal 200, last_response.status
      assert_equal 'Hello world!', last_response.body
    end
  end

  context ':except_hosts (Array)' do
    setup { mock_app :except_hosts => ["www.example.com", "example.com"] }

    should 'redirect to HTTPS for *.example.org' do
      get 'http://api.example.org'
      assert_equal 301, last_response.status
      assert_equal 'https://api.example.org/', last_response.location
    end

    should 'not redirect for www.example.com' do
      get "http://www.example.com"
      assert_equal 200, last_response.status
      assert_equal 'Hello world!', last_response.body
    end

    should 'not redirect for example.com' do
      get "http://example.com"
      assert_equal 200, last_response.status
      assert_equal 'Hello world!', last_response.body
    end
  end

  context ':only_hosts & :only' do
    setup { mock_app :only_hosts => "example.org", :only => '/foo' }

    should 'redirect to HTTPS for example.org/foo' do
      get 'http://example.org/foo'
      assert_equal 301, last_response.status
      assert_equal 'https://example.org/foo', last_response.location
    end

    should 'not redirect for example.org/bar' do
      get 'http://example.org/bar'
      assert_equal 200, last_response.status
      assert_equal 'Hello world!', last_response.body
    end

    should 'not redirect for www.example.org' do
      get 'http://www.example.org'
      assert_equal 200, last_response.status
      assert_equal 'Hello world!', last_response.body
    end

    should 'not redirect for www.example.org/foo' do
      get 'http://www.example.org/foo'
      assert_equal 200, last_response.status
      assert_equal 'Hello world!', last_response.body
    end

    should 'not redirect for www.example.org/bar' do
      get 'http://www.example.org/bar'
      assert_equal 200, last_response.status
      assert_equal 'Hello world!', last_response.body
    end
  end

  context ':only_hosts & :except' do
    setup { mock_app :only_hosts => "example.org", :except => '/foo' }

    should 'redirect to HTTPS for example.org/bar' do
      get 'http://example.org/bar'
      assert_equal 301, last_response.status
      assert_equal 'https://example.org/bar', last_response.location
    end

    should 'not redirect for example.org/foo' do
      get 'http://example.org/foo'
      assert_equal 200, last_response.status
      assert_equal 'Hello world!', last_response.body
    end

    should 'not redirect for www.example.org' do
      get 'http://www.example.org'
      assert_equal 200, last_response.status
      assert_equal 'Hello world!', last_response.body
    end

    should 'not redirect for www.example.org/bar' do
      get 'http://www.example.org/bar'
      assert_equal 200, last_response.status
      assert_equal 'Hello world!', last_response.body
    end

    should 'not redirect for www.example.org/foo' do
      get 'http://www.example.org/foo'
      assert_equal 200, last_response.status
      assert_equal 'Hello world!', last_response.body
    end
  end

  context ':except_hosts & :only' do
    setup { mock_app :except_hosts => "example.org", :only => '/foo' }

    should 'redirect to HTTPS for example.com/foo' do
      get 'http://example.com/foo'
      assert_equal 301, last_response.status
      assert_equal 'https://example.com/foo', last_response.location
    end

    should 'not redirect for example.org/foo' do
      get 'http://example.org/foo'
      assert_equal 200, last_response.status
      assert_equal 'Hello world!', last_response.body
    end

    should 'not redirect for example.com/bar' do
      get 'http://example.com/bar'
      assert_equal 200, last_response.status
      assert_equal 'Hello world!', last_response.body
    end

    should 'redirect to HTTPS for www.example.org/foo' do
      get 'http://www.example.org/foo'
      assert_equal 301, last_response.status
      assert_equal 'https://www.example.org/foo', last_response.location
    end

    should 'not redirect for www.example.org/bar' do
      get 'http://www.example.org/bar'
      assert_equal 200, last_response.status
      assert_equal 'Hello world!', last_response.body
    end
  end

  context ':except_hosts & :except' do
    setup { mock_app :except_hosts => "example.org", :except => '/foo' }

    should 'redirect to HTTPS for example.com/bar' do
      get 'http://example.com/bar'
      assert_equal 301, last_response.status
      assert_equal 'https://example.com/bar', last_response.location
    end

    should 'not redirect for example.org/foo' do
      get 'http://example.org/foo'
      assert_equal 200, last_response.status
      assert_equal 'Hello world!', last_response.body
    end

    should 'not redirect for example.org/bar' do
      get 'http://example.org/bar'
      assert_equal 200, last_response.status
      assert_equal 'Hello world!', last_response.body
    end

    should 'not redirect for example.com/foo' do
      get 'http://example.com/foo'
      assert_equal 200, last_response.status
      assert_equal 'Hello world!', last_response.body
    end

    should 'redirect to HTTPS for www.example.org/bar' do
      get 'http://www.example.org/bar'
      assert_equal 301, last_response.status
      assert_equal 'https://www.example.org/bar', last_response.location
    end

    should 'not redirect for www.example.org/foo' do
      get 'http://www.example.org/foo'
      assert_equal 200, last_response.status
      assert_equal 'Hello world!', last_response.body
    end
  end

  context ':except_hosts & :hsts == true & :strict == true' do
    setup { mock_app :except_hosts => /[www|api]\.example\.org$/, :hsts => true, :strict => true }

    should 'redirect to HTTP for www.example.org' do
      get 'https://www.example.org/'
      assert_equal 301, last_response.status
      assert_equal 'http://www.example.org/', last_response.location
    end

    should 'not redirect for abc.example.org' do
      get 'https://abc.example.org/'
      assert_equal 200, last_response.status
      assert_equal 'Hello world!', last_response.body
    end

    should 'not set hsts for www.example.org (HTTP)' do
      get 'http://www.example.org/'
      assert !last_response.headers["Strict-Transport-Security"]
    end

    should 'not set hsts for www.example.org (HTTPS)' do
      get 'https://www.example.org/'
      assert !last_response.headers["Strict-Transport-Security"]
    end

    should 'not set hsts for abc.example.org (HTTP)' do
      get 'http://abc.example.org/'
      assert !last_response.headers["Strict-Transport-Security"]
    end

    should 'not set hsts for abc.example.org (HTTPS)' do
      get 'https://abc.example.org/'
      assert !last_response.headers["Strict-Transport-Security"]
    end
  end

  context ':only == [] & :strict == true' do
    setup { mock_app :only => [], :strict => true }

    should 'not redirect for /foo (HTTP)' do
      get 'http://www.example.org/foo'
      assert_equal 200, last_response.status
      assert_equal 'Hello world!', last_response.body
    end

    should 'redirect to HTTP for /users.xml' do
      get 'https://www.example.org/users.xml'
      assert_equal 301, last_response.status
      assert_equal 'http://www.example.org/users.xml', last_response.location
    end
  end

  context ':only == nil & :strict = true' do
    setup { mock_app :only => nil, :strict => true }

    should 'redirect to HTTP for /users.xml' do
      get 'http://www.example.org/foo'
      assert_equal 301, last_response.status
      assert_equal 'https://www.example.org/foo', last_response.location
    end

    should 'not redirect for /users.xml' do
      get 'https://www.example.org/users.xml'
      assert_equal 200, last_response.status
      assert_equal 'Hello world!', last_response.body
    end
  end

  context ':mixed' do
    setup { mock_app :only => [/^\/users\/(.+)\/edit/], :mixed => true }

    should 'redirect to HTTPS for /foo' do
      get 'https://www.example.org/foo/'
      assert_equal 301, last_response.status
      assert_equal 'http://www.example.org/foo/', last_response.location
    end

    should 'not redirect for GET /users/123/edit' do
      get 'https://www.example.org/users/123/edit'
      assert_equal 200, last_response.status
      assert_equal 'Hello world!', last_response.body
    end

    should 'redirect to HTTPS for POST /users/123/edit' do
      post 'http://www.example.org/users/123/edit'
      assert_equal 301, last_response.status
      assert_equal 'https://www.example.org/users/123/edit', last_response.location
    end

    should 'redirect to HTTPS for PUT /users/123/edit' do
      put 'http://www.example.org/users/123/edit'
      assert_equal 301, last_response.status
      assert_equal 'https://www.example.org/users/123/edit', last_response.location
    end
  end

  context ':hsts' do
    setup { mock_app :hsts => { :expires => '500', :subdomains => false } }

    should 'set expiry option' do
      get 'https://www.example.org/'
      assert_equal "max-age=500", last_response.headers["Strict-Transport-Security"]
    end

    should 'not include subdomains' do
      get 'https://www.example.org/'
      assert !last_response.headers["Strict-Transport-Security"].include?("includeSubDomains")
    end
  end

  context ':force_secure_cookie == false' do
    setup { mock_app :force_secure_cookies => false }

    should 'not secure cookies but warn the user of the consequences' do
      get 'https://www.example.org/users/123/edit'
      assert_equal ["id=1; path=/", "token=abc; path=/; secure; HttpOnly"], last_response.headers['Set-Cookie'].split("\n")
    end
  end

  context ':only_methods' do
    setup { mock_app :only_methods => 'POST' }

    should 'redirect to HTTPS for POST request' do
      post 'http://www.example.org/'
      assert_equal 301, last_response.status
      assert_equal 'https://www.example.org/', last_response.location
    end

    should 'not redirect for PUT request' do
      put 'http://www.example.org/'
      assert_equal 200, last_response.status
      assert_equal 'Hello world!', last_response.body
    end

    should 'not redirect for GET request' do
      get 'http://www.example.org/'
      assert_equal 200, last_response.status
      assert_equal 'Hello world!', last_response.body
    end
  end

  context ':except_methods option' do
    setup { mock_app :except_methods => 'GET' }

    should 'redirect to HTTPS for POST request' do
      post 'http://www.example.org/'
      assert_equal 301, last_response.status
      assert_equal 'https://www.example.org/', last_response.location
    end

    should 'redirect to HTTPS for PUT request' do
      post 'http://www.example.org/'
      assert_equal 301, last_response.status
      assert_equal 'https://www.example.org/', last_response.location
    end

    should 'not redirect for GET request' do
      get 'http://www.example.org/'
      assert_equal 200, last_response.status
      assert_equal 'Hello world!', last_response.body
    end
  end

  context ':only_environments (String)' do
    setup { mock_app :only_environments => 'production' }

    should 'redirect to HTTPS for "production" environment' do
      ENV["RACK_ENV"] = "production"
      get 'http://www.example.org/'
      assert_equal 301, last_response.status
      assert_equal 'https://www.example.org/', last_response.location
    end

    should 'not redirect for "development" environment' do
      ENV["RACK_ENV"] = "development"
      get 'http://www.example.org/'
      assert_equal 200, last_response.status
      assert_equal 'Hello world!', last_response.body
    end
  end

  context ':only_environments (Array + Regex)' do
    setup { mock_app :only_environments => ['production', /QA\d+/] }

    should 'redirect to HTTPS for "production" environment' do
      ENV["RACK_ENV"] = "production"
      get 'http://www.example.org/'
      assert_equal 301, last_response.status
      assert_equal 'https://www.example.org/', last_response.location
    end

    should 'redirect to HTTPS for "QA2" environment' do
      ENV["RACK_ENV"] = "QA2"
      get 'http://www.example.org/'
      assert_equal 301, last_response.status
      assert_equal 'https://www.example.org/', last_response.location
    end

    should 'redirect to HTTPS for "QA15" environment' do
      ENV["RACK_ENV"] = "QA15"
      get 'http://www.example.org/'
      assert_equal 301, last_response.status
      assert_equal 'https://www.example.org/', last_response.location
    end

    should 'not redirect for "development" environment' do
      ENV["RACK_ENV"] = "development"
      get 'http://www.example.org/'
      assert_equal 200, last_response.status
      assert_equal 'Hello world!', last_response.body
    end
  end

  context ':except_environments (String)' do
    setup { mock_app :except_environments => 'development' }

    should 'redirect to HTTPS for "production" environment' do
      ENV["RACK_ENV"] = "production"
      get 'http://www.example.org/'
      assert_equal 301, last_response.status
      assert_equal 'https://www.example.org/', last_response.location
    end

    should 'not redirect for "development" environment' do
      ENV["RACK_ENV"] = "development"
      get 'http://www.example.org/'
      assert_equal 200, last_response.status
      assert_equal 'Hello world!', last_response.body
    end
  end

  context ':except_environments (Array + Regex)' do
    setup { mock_app :except_environments => ['development', /\w+_local/] }

    should 'redirect to HTTPS for "production" environment' do
      ENV["RACK_ENV"] = "production"
      get 'http://www.example.org/'
      assert_equal 301, last_response.status
      assert_equal 'https://www.example.org/', last_response.location
    end

    should 'not redirect for "development" environment' do
      ENV["RACK_ENV"] = "development"
      get 'http://www.example.org/'
      assert_equal 200, last_response.status
      assert_equal 'Hello world!', last_response.body
    end

    should 'not redirect for "jebediah_local" environment' do
      ENV["RACK_ENV"] = "jebediah_local"
      get 'http://www.example.org/'
      assert_equal 200, last_response.status
      assert_equal 'Hello world!', last_response.body
    end

    should 'not redirect for "el_guapo_local" environment' do
      ENV["RACK_ENV"] = "el_guapo_local"
      get 'http://www.example.org/'
      assert_equal 200, last_response.status
      assert_equal 'Hello world!', last_response.body
    end
  end

  context 'complex example' do
    setup { mock_app :only => '/cart', :ignore => %r{/assets}, :strict => true }

    should 'redirect to HTTPS for /cart' do
      get 'http://www.example.org/cart'
      assert_equal 301, last_response.status
      assert_equal 'https://www.example.org/cart', last_response.location
    end

    should 'redirect to HTTP for other paths' do
      get 'https://www.example.org/foo'
      assert_equal 301, last_response.status
      assert_equal 'http://www.example.org/foo', last_response.location
    end

    should 'leave HTTP as is for /assets' do
      get 'http://www.example.org/assets'
      assert_equal 200, last_response.status
      assert_equal 'Hello world!', last_response.body
    end

    should 'leave HTTPS as is for /assets' do
      get 'https://www.example.org/assets'
      assert_equal 200, last_response.status
      assert_equal 'Hello world!', last_response.body
    end
  end

  context 'default output' do
    setup { mock_app }

    should 'produce default output when redirecting' do
      get 'http://www.example.org/'
      assert_equal 301, last_response.status
      assert_equal last_response.body, '<html><body>You are being <a href="https://www.example.org/">redirected</a>.</body></html>'
    end
  end

  context 'no output' do
    setup { mock_app :redirect_html => false }

    should 'not produce output when redirecting' do
      get 'http://www.example.org/'
      assert_equal 301, last_response.status
      assert_empty last_response.body
    end
  end

  context 'custom string output' do
    setup { mock_app :redirect_html => "<html><body>Hello!</body></html>" }
      should 'produce custom output when redirecting' do
      get 'http://www.example.org/'
      assert_equal 301, last_response.status
      assert_equal last_response.body, '<html><body>Hello!</body></html>'
    end
  end

  context 'custom object output' do
    setup { mock_app :redirect_html => ['<html>','<body>','Hello!','</body>','</html>'] }
      should 'produce custom output when redirecting' do
      get 'http://www.example.org/'
      assert_equal 301, last_response.status
      assert_equal last_response.body, '<html><body>Hello!</body></html>'
    end
  end
end
