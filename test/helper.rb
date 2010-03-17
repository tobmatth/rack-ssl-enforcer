require 'rubygems'
require 'test/unit'
require 'shoulda'
require 'rack/mock'

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))

require 'rack-ssl-enforcer'

class Test::Unit::TestCase
end
