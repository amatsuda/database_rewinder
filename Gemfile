# frozen_string_literal: true

source 'https://rubygems.org'

# Specify your gem's dependencies in database_rewinder.gemspec
gemspec

if ENV['RAILS_VERSION'] == 'edge'
  gem 'rails', git: 'https://github.com/rails/rails.git'
elsif ENV['RAILS_VERSION']
  gem 'rails', "~> #{ENV['RAILS_VERSION']}.0"
else
  gem 'rails'
end

gem 'nokogiri', RUBY_VERSION < '2.1' ? '~> 1.6.0' : '>= 1.7'
gem 'selenium-webdriver'

rails_version = ENV['RAILS_VERSION'] || '∞'

case ENV['DB']
when 'postgresql'
  gem 'pg', rails_version <= '5.2' ? '~> 0.21' : '>= 1'
when 'mysql'
  if rails_version <= '4.1'
    gem 'mysql2', '~> 0.3.13'
  elsif rails_version <= '4.2'
    gem 'mysql2', '~> 0.4.0'
  else
    gem 'mysql2'
  end
else
  gem 'sqlite3', rails_version <= '5.0' ? '< 1.4' : '>= 1.4'
end
