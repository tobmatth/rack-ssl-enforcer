require 'helper'

class TestRackSslEnforcer < Test::Unit::TestCase

  def dummy_app(env)
    [ 200, {'Content-Type' => 'text/plain'}, 'Hello world!' ]
  end

  context 'Given an app' do
    setup do
      @app = method(:dummy_app)
    end

    context 'that has no :redirect_to set' do
      setup do
        @request  = Rack::MockRequest.new(Rack::SslEnforcer.new(@app))
      end
      
      should 'respond with a ssl redirect to plain-text requests' do
        response = @request.get('http://www.example.org/', {})
        assert_equal 301, response.status
        assert_equal response.location, 'https://www.example.org/'
      end

      #heroku / etc do proxied SSL
      #http://github.com/pivotal/refraction/issues/issue/2
      should 'respect X-Forwarded-Proto header for proxied SSL' do
        response = @request.get('http://www.example.org/',
                                {'HTTP_X_FORWARDED_PROTO' => 'http',
                                  'rack.url_scheme' => 'http'})
        assert_equal 301, response.status
        assert_equal response.location, 'https://www.example.org/'
      end
      
      should 'respond not redirect ssl requests' do
        response = @request.get('https://www.example.org/', {})
        assert_equal 200, response.status
        assert_equal response.body, 'Hello world!'
      end

      should 'respond not redirect ssl requests and respect X-Forwarded-Proto header for proxied SSL' do
         response = @request.get('http://www.example.org/',
                                {'HTTP_X_FORWARDED_PROTO' => 'https',
                                  'rack.url_scheme' => 'http'})
        assert_equal 200, response.status
        assert_equal response.body, 'Hello world!'
      end

    end
    
    context 'that has :redirect_to set' do
      setup do
        @request  = Rack::MockRequest.new(Rack::SslEnforcer.new(@app, :redirect_to => 'https://www.google.com/'))
      end
      
      should 'respond with a ssl redirect to plain-text requests and redirect to :redirect_to' do
        response = @request.get('http://www.example.org/', {})
        assert_equal 301, response.status
        assert_equal response.location, 'https://www.google.com/'
      end
      
      should 'respond not redirect ssl requests' do
        response = @request.get('https://www.example.org/', {})
        assert_equal 200, response.status
        assert_equal response.body, 'Hello world!'
      end
    end
    
    context 'that has :message set' do
      setup do
        @message = 'R-R-R-Redirect!'
        @request  = Rack::MockRequest.new(Rack::SslEnforcer.new(@app, :message => @message))
      end
      
      should 'output the given message when redirecting' do
        response = @request.get('http://www.example.org/', {})
        assert_equal 301, response.status
        assert_equal response.body, @message
      end
    end
    
  end

end
