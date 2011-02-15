# -*- encoding: utf-8 -*-
$LOAD_PATH.unshift File.expand_path('../lib', __FILE__)
require 'rack/ssl-enforcer/version'

Gem::Specification.new do |s|
  s.name        = "rack-ssl-enforcer"
  s.version     = Rack::SslEnforcer::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Tobias Matthies", "Thibaud Guillaume-Gentil"]
  s.email       = ["tm@mit2m.de", "thibaud@thibaud.me"]
  s.homepage    = "http://github.com/tobmatth/rack-ssl-enforcer"
  s.summary     = "A simple Rack middleware to enforce SSL"
  s.description = "Rack::SslEnforcer is a simple Rack middleware to enforce ssl connections"

  s.required_rubygems_version = ">= 1.3.6"
  s.rubyforge_project         = "rack-ssl-enforcer"

  s.add_development_dependency "guard",      "~> 0.3.0"
  s.add_development_dependency "guard-test", "~> 0.1.6"
  s.add_development_dependency "bundler",    "~> 1.0.10"
  s.add_development_dependency "test-unit",  "~> 2.1.1"
  s.add_development_dependency "shoulda",    "~> 2.11.3"
  s.add_development_dependency "rack",       "~> 1.2.0"
  s.add_development_dependency "rack-test",  "~> 0.5.4"

  s.files        = Dir.glob("{lib}/**/*") + %w[LICENSE README.rdoc]
  s.require_path = 'lib'
end
