source :rubygems

gemspec

gem 'rake'
gem 'guard-test'

require 'rbconfig'

group :development do
  gem 'rdoc'
  gem 'guard'

  if RbConfig::CONFIG['target_os'] =~ /darwin/i
    gem 'rb-fsevent', '~> 0.4'
    gem 'growl'
  end
  
  if RbConfig::CONFIG['target_os'] =~ /linux/i
    gem 'rb-inotify', '~> 0.5.1'
    gem 'libnotify',  '~> 0.1.3'
  end
end

