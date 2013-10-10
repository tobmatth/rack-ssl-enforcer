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

  def mock_app(options_or_options_array = {})
    main_app = lambda { |env|
      request = Rack::Request.new(env)
      headers = {'Content-Type' => "text/html"}
      headers['Set-Cookie'] = "id=1; path=/\ntoken=abc; path=/; secure; HttpOnly"
      [200, headers, ['Hello world!']]
    }

    builder = Rack::Builder.new
    options_or_options_array = [options_or_options_array] unless options_or_options_array.is_a?(Array)
    Array(options_or_options_array).each do |options|
      builder.use Rack::SslEnforcer, options
    end
    builder.run main_app
    @app = builder.to_app
  end

end
