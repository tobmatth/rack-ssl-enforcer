# A sample Guardfile
# More info at http://github.com/guard/guard#readme

guard 'bundler' do
  watch('^Gemfile')
  watch('^.+\.gemspec')
end

guard 'test' do
  watch('^lib\/(.*)\.rb')        { "test/rack-ssl-enforcer_test.rb" }
  watch('^test\/helper.rb')      { "test" }
  watch('^test\/(.*)_test\.rb')
end 
