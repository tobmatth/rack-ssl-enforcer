require 'rubygems'
require 'test/unit'
require 'shoulda'
require 'rack/mock'
require 'rack/test'

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'rack/ssl-enforcer'

class Test::Unit::TestCase
  include Rack::Test::Methods

  def app; Rack::Lint.new(@app); end

  def mock_app(options = {})
    main_app = lambda { |env|
      request = Rack::Request.new(env)
      headers = {'Content-Type' => "text/html"}
      headers['Set-Cookie'] = "id=1; path=/\ntoken=abc; path=/; secure; HttpOnly"
      [200, headers, ['Hello world!']]
    }

    builder = Rack::Builder.new
    builder.use Rack::SslEnforcer, options
    builder.run main_app
    @app = builder.to_app
  end

end
