source 'https://rubygems.org'

gemspec

if RUBY_PLATFORM == 'java'
  gem 'activerecord-jdbcpostgresql-adapter'
else
  gem 'pg'
end

gem 'activerecord-testcase'
gem 'guard'
gem 'guard-minitest'
gem 'minitest'
gem 'minitest-reporters'
gem 'rake'
gem 'rdoc'
gem 'simplecov'

if File.exists?('Gemfile.local')
  instance_eval File.read('Gemfile.local')
end
