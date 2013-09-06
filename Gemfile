source 'https://rubygems.org'

gemspec

gem 'rake'

# The development group will no be
# installed on Travis CI.
#
group :development do
  require 'rbconfig'

  if RbConfig::CONFIG['target_os'] =~ /darwin/i
    gem 'ruby_gntp', :require => false

  elsif RbConfig::CONFIG['target_os'] =~ /linux/i
    gem 'libnotify',  '~> 0.8.0', :require => false

  elsif RbConfig::CONFIG['target_os'] =~ /mswin|mingw/i
    gem 'win32console', :require => false
    gem 'rb-notifu', '>= 0.0.4', :require => false
  end

  gem 'guard-test'
end

# The test group will be
# installed on Travis CI
#
group :test do
  gem 'rack-test', '~> 0.5.4'
  gem 'test-unit', '~> 2.3'
  gem 'shoulda',   '~> 2.11.3'
end
