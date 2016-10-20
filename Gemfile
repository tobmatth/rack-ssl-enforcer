source 'https://rubygems.org'

gemspec

gem 'rake', '~> 10.5.0' if RUBY_VERSION < '1.9.3'
gem 'rake' if RUBY_VERSION >= '1.9.3'

# The development group will no be
# installed on Travis CI.
#
group :development do
  gem 'ruby_gntp', :require => false
  gem 'guard-test'
end

# The test group will be
# installed on Travis CI
#
group :test do
  gem 'rack-test'
  gem 'test-unit', '~> 2.5' if RUBY_VERSION < '1.9.3'
  gem 'test-unit' if RUBY_VERSION >= '1.9.3'
  gem 'shoulda', '~> 2.11.3'
end

platforms :rbx do
  gem 'racc'
  gem 'rubysl', '~> 2.0'
  gem 'psych'
end
