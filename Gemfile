source 'https://rubygems.org'

gemspec

gem 'rake'

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
  gem 'test-unit'
  gem 'shoulda', '~> 2.11.3'
end
