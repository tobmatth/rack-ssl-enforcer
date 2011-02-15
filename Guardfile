# A sample Guardfile
# More info at http://github.com/guard/guard#readme

guard 'test' do
  watch(%r{^lib/(.*)\.rb})       { "test/rack-ssl-enforcer_test.rb" }
  watch('test/helper.rb')        { "test" }
  watch(%r{^test/(.*)_test\.rb})
end
