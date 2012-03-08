source :rubygems

# Specify your gem's dependencies in rack-ssl-enforcer.gemspec
gemspec

gem 'rake'

group :guard do
  gem 'guard'
  gem 'guard-test'

  if Config::CONFIG['target_os'] =~ /darwin/i
    gem 'rb-fsevent', '~> 0.4'
    gem 'growl'
  elsif Config::CONFIG['target_os'] =~ /linux/i
    gem 'rb-inotify', '~> 0.5.1'
    gem 'libnotify',  '~> 0.1.3'
  end
end

