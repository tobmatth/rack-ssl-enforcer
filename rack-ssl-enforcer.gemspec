# -*- encoding: utf-8 -*-
$LOAD_PATH.unshift File.expand_path('../lib', __FILE__)
require 'rack/ssl-enforcer/version'

Gem::Specification.new do |s|
  s.name        = "rack-ssl-enforcer"
  s.version     = Rack::SslEnforcer::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Tobias Matthies"]
  s.email       = ["tm@mit2m.de"]
  s.homepage    = "http://github.com/tobmatth/rack-ssl-enforcer"
  s.summary     = "A simple Rack middleware to enforce SSL"
  s.description = "Write a gem description!"
  
  s.required_rubygems_version = ">= 1.3.6"
  s.rubyforge_project         = "rack-ssl-enforcer"
  
  s.add_development_dependency "bundler", ">= 1.0.0"
  s.add_development_dependency "shoulda", "~> 2.11.3"
  s.add_development_dependency "rack", "~> 1.2.0"
  
  s.files        = Dir.glob("{lib}/**/*") + %w[LICENSE README.rdoc]
  s.require_path = 'lib'
end