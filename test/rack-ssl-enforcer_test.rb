require 'helper'

class TestRackSslEnforcer < Test::Unit::TestCase

  context 'that has no :redirect_to set' do
    setup { mock_app }

    should 'respond with a ssl redirect to plain-text requests' do
      get 'http://www.example.org/'
      assert_equal 301, last_response.status
      assert_equal 'https://www.example.org/', last_response.location
    end

    should 'respond with a ssl redirect to plain-text requests and keep params' do
      get 'http://www.example.org/admin?token=33'
      assert_equal 301, last_response.status
      assert_equal 'https://www.example.org/admin?token=33', last_response.location
    end

    #heroku / etc do proxied SSL
    #http://github.com/pivotal/refraction/issues/issue/2
    should 'respect X-Forwarded-Proto header for proxied SSL' do
      get 'http://www.example.org/', {}, { 'HTTP_X_FORWARDED_PROTO' => 'http', 'rack.url_scheme' => 'http' }
      assert_equal 301, last_response.status
      assert_equal 'https://www.example.org/', last_response.location
    end

    should 'respond not redirect ssl requests' do
      get 'https://www.example.org/'
      assert_equal 200, last_response.status
      assert_equal 'Hello world!', last_response.body
    end

    should 'respond not redirect ssl requests and respect X-Forwarded-Proto header for proxied SSL' do
      get 'http://www.example.org/', {}, { 'HTTP_X_FORWARDED_PROTO' => 'https', 'rack.url_scheme' => 'http' }
      assert_equal 200, last_response.status
      assert_equal 'Hello world!', last_response.body
    end

    should 'use default https port when redirecting non-standard http port to ssl' do
      get 'http://example.org:81/', {}, { 'rack.url_scheme' => 'http' }
      assert_equal 301, last_response.status
      assert_equal 'https://example.org/', last_response.location
    end

    should 'secure cookies' do
      get 'https://www.example.org/'
      assert_equal ["id=1; path=/; secure", "token=abc; path=/; secure; HttpOnly"], last_response.headers['Set-Cookie'].split("\n")
    end

    should 'not set default hsts headers to all ssl requests' do
      get 'https://www.example.org/'
      assert !last_response.headers["Strict-Transport-Security"]
    end

    should 'not set hsts headers to non ssl requests' do
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

    should 'secure multiple cookies' do
      get 'https://www.example.org/'
      assert_equal ["id=1; path=/; secure", "token=abc; path=/; HttpOnly; secure"], last_response.headers['Set-Cookie'].split("\n")
    end
  end


  context 'that has :ssl_port set' do
    setup { mock_app :https_port => 9443 }

    should 'respond with a ssl redirect to plain-text requests and redirect to a custom port' do
      get 'http://www.example.org/'
      assert_equal 301, last_response.status
      assert_equal 'https://www.example.org:9443/', last_response.location
    end
  end

  context 'that has a default :ssl_port set' do
    setup { mock_app :https_port => 443 }

    should 'respond with a ssl redirect to plain-text requests and redirect without a port identifier' do
      get 'http://www.example.org/'
      assert_equal 301, last_response.status
      assert_equal 'https://www.example.org/', last_response.location
    end
  end

  context 'that has :redirect_to set' do
    setup { mock_app :redirect_to => 'https://www.google.com' }

    should 'respond with a ssl redirect to plain-text requests and redirect to :redirect_to' do
      get 'http://www.example.org/'
      assert_equal 301, last_response.status
      assert_equal 'https://www.google.com/', last_response.location
    end

    should 'respond with a ssl redirect to plain-text requests and redirect to :redirect_to and keep params' do
      get 'http://www.example.org/admin?token=33'
      assert_equal 301, last_response.status
      assert_equal 'https://www.google.com/admin?token=33', last_response.location
    end

    should 'redirect to :redirect_to when host without scheme given' do
      mock_app :redirect_to => 'www.google.com'

      get 'http://www.example.org/'
      assert_equal 301, last_response.status
      assert_equal 'https://www.google.com/', last_response.location
    end

    should 'respond not redirect ssl requests' do
      get 'https://www.example.org/'
      assert_equal 200, last_response.status
      assert_equal 'Hello world!', last_response.body
    end
  end

  context 'that has a regex pattern as :only option' do
    setup { mock_app :only => /^\/admin/ }

    should 'respond with a ssl redirect for /admin path' do
      get 'http://www.example.org/admin'
      assert_equal 301, last_response.status
      assert_equal 'https://www.example.org/admin', last_response.location
    end

    should 'respond not redirect ssl requests' do
      get 'http://www.example.org/foo'
      assert_equal 200, last_response.status
      assert_equal 'Hello world!', last_response.body
    end

    should 'secure cookies' do
      get 'https://www.example.org/'
      assert_equal ["id=1; path=/; secure", "token=abc; path=/; secure; HttpOnly"], last_response.headers['Set-Cookie'].split("\n")
    end
  end

  context 'that has a string path as :only option' do
    setup { mock_app :only => "/login" }

    should 'respond with a ssl redirect for /login path' do
      get 'http://www.example.org/login'
      assert_equal 301, last_response.status
      assert_equal 'https://www.example.org/login', last_response.location
    end

    should 'respond not redirect ssl requests' do
      get 'http://www.example.org/foo/'
      assert_equal 200, last_response.status
      assert_equal 'Hello world!', last_response.body
    end
  end

  context 'that has an array of regex patterns & string paths as :only option' do
    setup { mock_app :only => [/\.xml$/, "/login"] }

    should 'respond with a ssl redirect for /login path' do
      get 'http://www.example.org/login'
      assert_equal 301, last_response.status
      assert_equal 'https://www.example.org/login', last_response.location
    end

    should 'respond with a ssl redirect for /admin path' do
      get 'http://www.example.org/users.xml'
      assert_equal 301, last_response.status
      assert_equal 'https://www.example.org/users.xml', last_response.location
    end

    should 'respond not redirect ssl requests' do
      get 'http://www.example.org/foo/'
      assert_equal 200, last_response.status
      assert_equal 'Hello world!', last_response.body
    end
  end

  context 'that has an array of regex patterns & string paths as :only option with :strict = true' do
    setup { mock_app :only => [/\.xml$/, "/login"], :strict => true }

    should 'respond with a http redirect from non-allowed https url' do
      get 'https://www.example.org/foo/'
      assert_equal 301, last_response.status
      assert_equal 'http://www.example.org/foo/', last_response.location
    end

    should 'respond from allowed https url' do
      get 'https://www.example.org/login'
      assert_equal 200, last_response.status
      assert_equal 'Hello world!', last_response.body
    end

    should 'use default https port when redirecting non-standard ssl port to http' do
      get 'https://example.org:81/', {}, { 'rack.url_scheme' => 'https' }
      assert_equal 301, last_response.status
      assert_equal 'http://example.org/', last_response.location
    end

    should 'secure cookies' do
      get 'https://www.example.org/login'
      assert_equal ["id=1; path=/; secure", "token=abc; path=/; secure; HttpOnly"], last_response.headers['Set-Cookie'].split("\n")
    end

    should 'not secure cookies' do
      get 'http://www.example.org/'
      assert_equal ["id=1; path=/", "token=abc; path=/; secure; HttpOnly"], last_response.headers['Set-Cookie'].split("\n")
    end
  end

  context 'that has a regex pattern as :except option' do
    setup { mock_app :except => /^\/foo/ }

    should 'respond with a ssl redirect for /admin path' do
      get 'http://www.example.org/admin'
      assert_equal 301, last_response.status
      assert_equal 'https://www.example.org/admin', last_response.location
    end

    should 'respond not redirect ssl requests' do
      get 'http://www.example.org/foo'
      assert_equal 200, last_response.status
      assert_equal 'Hello world!', last_response.body
    end

    should 'secure cookies' do
      get 'https://www.example.org/'
      assert_equal ["id=1; path=/; secure", "token=abc; path=/; secure; HttpOnly"], last_response.headers['Set-Cookie'].split("\n")
    end
  end

  context 'that has a string path as :except option' do
    setup { mock_app :except => "/foo" }

    should 'respond with a ssl redirect for /login path' do
      get 'http://www.example.org/login'
      assert_equal 301, last_response.status
      assert_equal 'https://www.example.org/login', last_response.location
    end

    should 'respond not redirect ssl requests' do
      get 'http://www.example.org/foo/'
      assert_equal 200, last_response.status
      assert_equal 'Hello world!', last_response.body
    end
  end

  context 'that has an array of regex patterns & string paths as :except option' do
    setup { mock_app :except => [/^\/foo/, "/bar"] }

    should 'respond with a ssl redirect for /admin path' do
      get 'http://www.example.org/admin'
      assert_equal 301, last_response.status
      assert_equal 'https://www.example.org/admin', last_response.location
    end

    should 'not redirect ssl requests for /foo path' do
      get 'http://www.example.org/foo'
      assert_equal 200, last_response.status
      assert_equal 'Hello world!', last_response.body
    end

    should 'not redirect ssl requests for /bar path' do
      get 'http://www.example.org/bar'
      assert_equal 200, last_response.status
      assert_equal 'Hello world!', last_response.body
    end

  end

  context 'that has a string path as :except option with :strict = true' do
    setup { mock_app :except => "/foo", :strict => true }

    should 'respond with a http redirect from non-allowed https url' do
      get 'https://www.example.org/foo/'
      assert_equal 301, last_response.status
      assert_equal 'http://www.example.org/foo/', last_response.location
    end

    should 'respond from allowed https url' do
      get 'https://www.example.org/login'
      assert_equal 200, last_response.status
      assert_equal 'Hello world!', last_response.body
    end

    should 'use default https port when redirecting non-standard ssl port to http' do
      get 'https://example.org:81/foo', {}, { 'rack.url_scheme' => 'https' }
      assert_equal 301, last_response.status
      assert_equal 'http://example.org/foo', last_response.location
    end

    should 'secure cookies' do
      get 'https://www.example.org/'
      assert_equal ["id=1; path=/; secure", "token=abc; path=/; secure; HttpOnly"], last_response.headers['Set-Cookie'].split("\n")
    end

    should 'not secure cookies' do
      get 'http://www.example.org/foo'
      assert_equal ["id=1; path=/", "token=abc; path=/; secure; HttpOnly"], last_response.headers['Set-Cookie'].split("\n")
    end
  end

  context 'that has a string domain as :only_hosts option' do
    setup { mock_app :only_hosts => "example.org" }

    should 'respond with a ssl redirect for example.org' do
      get 'http://example.org'
      assert_equal 301, last_response.status
      assert_equal 'https://example.org/', last_response.location
    end

    should 'respond not redirect ssl requests for *.example.org' do
      get 'http://www.example.org'
      assert_equal 200, last_response.status
      assert_equal 'Hello world!', last_response.body
    end

    should 'respond not redirect ssl requests' do
      get 'http://www.example.com'
      assert_equal 200, last_response.status
      assert_equal 'Hello world!', last_response.body
    end
  end

  context 'that has a string domain as :only_hosts option & a string path as :only option' do
    setup { mock_app :only_hosts => "example.org", :only => '/foo' }

    should 'respond with a ssl redirect for example.org/foo' do
      get 'http://example.org/foo'
      assert_equal 301, last_response.status
      assert_equal 'https://example.org/foo', last_response.location
    end

    should 'respond not redirect ssl requests for example.org/bar' do
      get 'http://example.org/bar'
      assert_equal 200, last_response.status
      assert_equal 'Hello world!', last_response.body
    end

    should 'respond not redirect ssl requests for www.example.org' do
      get 'http://www.example.org'
      assert_equal 200, last_response.status
      assert_equal 'Hello world!', last_response.body
    end

    should 'respond not redirect ssl requests for www.example.org/foo' do
      get 'http://www.example.org/foo'
      assert_equal 200, last_response.status
      assert_equal 'Hello world!', last_response.body
    end

    should 'respond not redirect ssl requests for www.example.org/bar' do
      get 'http://www.example.org/bar'
      assert_equal 200, last_response.status
      assert_equal 'Hello world!', last_response.body
    end
  end

  context 'that has a string domain as :only_hosts option & a string path as :except option' do
    setup { mock_app :only_hosts => "example.org", :except => '/foo' }

    should 'respond with a ssl redirect for example.org/bar' do
      get 'http://example.org/bar'
      assert_equal 301, last_response.status
      assert_equal 'https://example.org/bar', last_response.location
    end

    should 'respond not redirect ssl requests for example.org/foo' do
      get 'http://example.org/foo'
      assert_equal 200, last_response.status
      assert_equal 'Hello world!', last_response.body
    end

    should 'respond not redirect ssl requests for www.example.org' do
      get 'http://www.example.org'
      assert_equal 200, last_response.status
      assert_equal 'Hello world!', last_response.body
    end

    should 'respond not redirect ssl requests for www.example.org/bar' do
      get 'http://www.example.org/bar'
      assert_equal 200, last_response.status
      assert_equal 'Hello world!', last_response.body
    end

    should 'respond not redirect ssl requests for www.example.org/foo' do
      get 'http://www.example.org/foo'
      assert_equal 200, last_response.status
      assert_equal 'Hello world!', last_response.body
    end
  end

  context 'that has a string domain as :except_hosts option & a string path as :only option' do
    setup { mock_app :except_hosts => "example.org", :only => '/foo' }

    should 'respond with a ssl redirect for example.com/foo' do
      get 'http://example.com/foo'
      assert_equal 301, last_response.status
      assert_equal 'https://example.com/foo', last_response.location
    end

    should 'respond not redirect ssl requests for example.org/foo' do
      get 'http://example.org/foo'
      assert_equal 200, last_response.status
      assert_equal 'Hello world!', last_response.body
    end

    should 'respond not redirect ssl requests for example.com/bar' do
      get 'http://example.com/bar'
      assert_equal 200, last_response.status
      assert_equal 'Hello world!', last_response.body
    end

    should 'respond with a ssl redirect for www.example.org/foo' do
      get 'http://www.example.org/foo'
      assert_equal 301, last_response.status
      assert_equal 'https://www.example.org/foo', last_response.location
    end

    should 'respond not redirect ssl requests for www.example.org/bar' do
      get 'http://www.example.org/bar'
      assert_equal 200, last_response.status
      assert_equal 'Hello world!', last_response.body
    end
  end

  context 'that has a string domain as :except_hosts option & a string path as :except option' do
    setup { mock_app :except_hosts => "example.org", :except => '/foo' }

    should 'respond with a ssl redirect for example.com/bar' do
      get 'http://example.com/bar'
      assert_equal 301, last_response.status
      assert_equal 'https://example.com/bar', last_response.location
    end

    should 'respond not redirect ssl requests for example.org/foo' do
      get 'http://example.org/foo'
      assert_equal 200, last_response.status
      assert_equal 'Hello world!', last_response.body
    end

    should 'respond not redirect ssl requests for example.org/bar' do
      get 'http://example.org/bar'
      assert_equal 200, last_response.status
      assert_equal 'Hello world!', last_response.body
    end

    should 'respond not redirect ssl requests for example.com/foo' do
      get 'http://example.com/foo'
      assert_equal 200, last_response.status
      assert_equal 'Hello world!', last_response.body
    end

    should 'respond with a ssl redirect for www.example.org/bar' do
      get 'http://www.example.org/bar'
      assert_equal 301, last_response.status
      assert_equal 'https://www.example.org/bar', last_response.location
    end

    should 'respond not redirect ssl requests for www.example.org/foo' do
      get 'http://www.example.org/foo'
      assert_equal 200, last_response.status
      assert_equal 'Hello world!', last_response.body
    end
  end

  context 'that has an array of regex patterns & string domains as :only_hosts option' do
    setup { mock_app :only_hosts => [/[www|api]\.example\.org$/, "example.com"] }

    should 'respond with a ssl redirect for www.example.org' do
      get 'http://www.example.org'
      assert_equal 301, last_response.status
      assert_equal 'https://www.example.org/', last_response.location
    end

    should 'respond with a ssl redirect for api.example.org' do
      get 'http://api.example.org'
      assert_equal 301, last_response.status
      assert_equal 'https://api.example.org/', last_response.location
    end

    should 'respond not redirect ssl requests for *.example.com' do
      get 'http://goo.example.com'
      assert_equal 200, last_response.status
      assert_equal 'Hello world!', last_response.body
    end

    should 'respond not redirect ssl requests for example.org' do
      get 'http://example.org'
      assert_equal 200, last_response.status
      assert_equal 'Hello world!', last_response.body
    end

    should 'respond not redirect ssl requests for goo.example.org' do
      get 'http://goo.example.org'
      assert_equal 200, last_response.status
      assert_equal 'Hello world!', last_response.body
    end
  end

  context 'that has a regex pattern as :only_hosts option' do
    setup { mock_app :only_hosts => /[www|api]\.example\.co\.uk$/ }

    should 'respond with a ssl redirect for www.example.co.uk' do
      get 'http://www.example.co.uk'
      assert_equal 301, last_response.status
      assert_equal 'https://www.example.co.uk/', last_response.location
    end

    should 'respond with a ssl redirect for api.example.co.uk' do
      get 'http://api.example.co.uk'
      assert_equal 301, last_response.status
      assert_equal 'https://api.example.co.uk/', last_response.location
    end

    should 'respond not redirect ssl requests for goo.example.co.uk' do
      get 'http://goo.example.co.uk'
      assert_equal 200, last_response.status
      assert_equal 'Hello world!', last_response.body
    end

    should 'respond not redirect ssl requests for goo.example.co.uk for goo.example.co.uk' do
      get 'http://teambox.example.co.uk'
      assert_equal 200, last_response.status
      assert_equal 'Hello world!', last_response.body
    end
  end

  context 'that has an array of regex patterns & string domains as :only_hosts option with :strict = true' do
    setup { mock_app :only_hosts => [/[www|api]\.example\.org$/, "example.com"], :strict => true }

    should 'respond with a http redirect from non-allowed https url' do
      get 'https://abc.example.org/'
      assert_equal 301, last_response.status
      assert_equal 'http://abc.example.org/', last_response.location
    end

    should 'respond from allowed https url' do
      get 'https://www.example.org/'
      assert_equal 200, last_response.status
      assert_equal 'Hello world!', last_response.body
    end

    should 'use default https port when redirecting non-standard ssl port to http' do
      get 'https://goo.example.org:80/', {}, { 'rack.url_scheme' => 'https' }
      assert_equal 301, last_response.status
      assert_equal 'http://goo.example.org/', last_response.location
    end

    should 'secure cookies' do
      get 'https://www.example.org/'
      assert_equal ["id=1; path=/; secure", "token=abc; path=/; secure; HttpOnly"], last_response.headers['Set-Cookie'].split("\n")
    end

    should 'not secure cookies' do
      get 'http://goo.example.org/'
      assert_equal ["id=1; path=/", "token=abc; path=/; secure; HttpOnly"], last_response.headers['Set-Cookie'].split("\n")
    end
  end

  context 'that has a string domain as :except_hosts option' do
    setup { mock_app :except_hosts => "www.example.org" }

    should 'respond with a ssl redirect for *.example.org' do
      get 'http://api.example.org'
      assert_equal 301, last_response.status
      assert_equal 'https://api.example.org/', last_response.location
    end

    should 'respond not redirect ssl requests' do
      get 'http://www.example.org'
      assert_equal 200, last_response.status
      assert_equal 'Hello world!', last_response.body
    end
  end

  context 'that has an array of domains as :except_hosts option' do
    setup { mock_app :except_hosts => ["www.example.com", "example.com"] }

    should 'respond with a ssl redirect for *.example.org' do
      get 'http://api.example.org'
      assert_equal 301, last_response.status
      assert_equal 'https://api.example.org/', last_response.location
    end

    should 'not redirect www.example.com' do
      get "http://www.example.com"
      assert_equal 200, last_response.status
      assert_equal 'Hello world!', last_response.body
    end

    should 'not redirect example.com' do
      get "http://example.com"
      assert_equal 200, last_response.status
      assert_equal 'Hello world!', last_response.body
    end
  end

  context 'that has a regex pattern as :except_hosts option' do
    setup { mock_app :except_hosts => /[www|api]\.example\.co\.uk$/ }

    should 'respond with a ssl redirect for goo.example.co.uk' do
      get 'http://goo.example.co.uk'
      assert_equal 301, last_response.status
      assert_equal 'https://goo.example.co.uk/', last_response.location
    end

    should 'respond not redirect ssl requests for www.example.co.uk' do
      get 'http://api.example.co.uk'
      assert_equal 200, last_response.status
      assert_equal 'Hello world!', last_response.body
    end

    should 'respond not redirect ssl requests for api.example.co.uk' do
      get 'http://api.example.co.uk'
      assert_equal 200, last_response.status
      assert_equal 'Hello world!', last_response.body
    end
  end

  context 'that has a regex pattern as :except_hosts option with :hsts = true & :strict = true' do
    setup { mock_app :except_hosts => /[www|api]\.example\.org$/, :hsts => true, :strict => true }

    should 'respond with a http redirect from non-allowed https url' do
      get 'https://www.example.org/'
      assert_equal 301, last_response.status
      assert_equal 'http://www.example.org/', last_response.location
    end

    should 'respond from allowed https url' do
      get 'https://abc.example.org/'
      assert_equal 200, last_response.status
      assert_equal 'Hello world!', last_response.body
    end

    should 'use default https port when redirecting non-standard ssl port to http' do
      get 'https://www.example.org:80/', {}, { 'rack.url_scheme' => 'https' }
      assert_equal 301, last_response.status
      assert_equal 'http://www.example.org/', last_response.location
    end

    should 'secure cookies' do
      get 'https://goo.example.org/'
      assert_equal ["id=1; path=/; secure", "token=abc; path=/; secure; HttpOnly"], last_response.headers['Set-Cookie'].split("\n")
    end

    should 'not secure cookies' do
      get 'http://www.example.org/'
      assert_equal ["id=1; path=/", "token=abc; path=/; secure; HttpOnly"], last_response.headers['Set-Cookie'].split("\n")
    end

    should 'not set hsts from non-allowed http url' do
      get 'http://www.example.org/'
      assert !last_response.headers["Strict-Transport-Security"]
    end

    should 'not set hsts from non-allowed https url' do
      get 'https://www.example.org/'
      assert !last_response.headers["Strict-Transport-Security"]
    end

    should 'not set hsts from allowed http url' do
      get 'http://abc.example.org/'
      assert !last_response.headers["Strict-Transport-Security"]
    end

    should 'not set hsts from allowed https url' do
      get 'https://abc.example.org/'
      assert !last_response.headers["Strict-Transport-Security"]
    end
  end

  context 'that has an empty array as :only option & :strict = true' do
    setup { mock_app :only => [], :strict => true }

    should 'respond with no redirect for /foo path' do
      get 'http://www.example.org/foo'
      assert_equal 200, last_response.status
      assert_equal 'Hello world!', last_response.body
    end

    should 'respond with a non-ssl redirect for /users.xml path' do
      get 'https://www.example.org/users.xml'
      assert_equal 301, last_response.status
      assert_equal 'http://www.example.org/users.xml', last_response.location
    end
  end
  
  context 'that has array of regex pattern & path as only option with strict option and post option' do
    setup { mock_app :only => [/^\/users\/(.+)\/edit/], :mixed => true }
    
    should 'respond with a http redirect from non-allowed https url' do
      get 'https://www.example.org/foo/'
      assert_equal 301, last_response.status
      assert_equal 'http://www.example.org/foo/', last_response.location
    end
    
    should 'respond from allowed https url' do
      get 'https://www.example.org/users/123/edit'
      assert_equal 200, last_response.status
      assert_equal 'Hello world!', last_response.body
    end
    
    should 'use default https port when redirecting non-standard ssl port to http' do
      get 'https://example.org:81/', {}, { 'rack.url_scheme' => 'https' }
      assert_equal 301, last_response.status
      assert_equal 'http://example.org/', last_response.location
    end

    should 'secure cookies' do
      get 'https://www.example.org/users/123/edit'
      assert_equal ["id=1; path=/; secure", "token=abc; path=/; secure; HttpOnly"], last_response.headers['Set-Cookie'].split("\n")
    end
    
    should 'not secure cookies' do
      get 'http://www.example.org/'
      assert_equal ["id=1; path=/", "token=abc; path=/; secure; HttpOnly"], last_response.headers['Set-Cookie'].split("\n")
    end
    
    should 'not redirect if post' do
      post 'https://www.example.org/users/'
      assert_equal 200, last_response.status
      assert_equal 'Hello world!', last_response.body
    end
    
    should 'not redirect if put' do
      put 'https://www.example.org/users/123'
      assert_equal 200, last_response.status
      assert_equal 'Hello world!', last_response.body
    end
  end
  
  context 'that has hsts options set' do
    setup { mock_app :hsts => {:expires => '500', :subdomains => false} }

    should 'set expiry option' do
      get 'https://www.example.org/'
      assert_equal "max-age=500", last_response.headers["Strict-Transport-Security"]
    end

    should 'not include subdomains' do
      get 'https://www.example.org/'
      assert !last_response.headers["Strict-Transport-Security"].include?("includeSubDomains")
    end
  end
  
  context 'that has force_secure_cookie option set to false' do
    $stderr = StringIO.new
    setup { mock_app :force_secure_cookies => false }
    
    should 'not secure cookies but warn the user of the consequences' do
      get 'https://www.example.org/users/123/edit'
      assert_equal ["id=1; path=/", "token=abc; path=/; secure; HttpOnly"], last_response.headers['Set-Cookie'].split("\n")
      $stderr.rewind
      assert_equal "WARN -- : The option :force_secure_cookies is set to false so make sure your cookies are encoded and that you understand the consequences (see documentation)\n", $stderr.read
    end
  end

end
