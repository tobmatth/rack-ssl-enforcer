source 'https://rubygems.org'

gemspec

gem 'rake'

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
