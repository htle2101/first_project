source 'http://ruby.taobao.org'
#source 'https://rubygems.org'

gem 'rails', '3.2.11'
gem 'mysql2', '0.3.11'

# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'sass-rails',   '~> 3.2.3'
  gem 'coffee-rails', '~> 3.2.1'
  # See https://github.com/sstephenson/execjs#readme for more supported runtimes
  gem 'therubyracer', '0.10.2'
  gem 'uglifier', '>= 1.0.3'
  gem 'turbo-sprockets-rails3'
end

# auth & role
gem 'devise', '2.0.4'
gem 'omniauth', "~> 1.1.0"
gem 'omniauth-facebook', '1.4.1'
gem 'cancan', '~>1.6.8'
gem 'galetahub-simple_captcha', '0.1.3', :require => "simple_captcha"

# js & css
gem 'jquery-rails', '2.0.2'
gem "twitter-bootstrap-rails", '2.1.9'
gem 'execjs', '1.3.2'
gem 'sass', '3.1.16'
gem 'less-rails'

# query enhance
gem 'squeel', "1.0.1"
gem 'ransack', "0.6.0"

# web page crawl & extract
gem 'nokogiri', '1.5.0'
gem 'hpricot', '0.8.4'
gem 'mechanize'
# image process & upload
gem 'carrierwave', '0.6.2'
gem 'mini_magick', '3.2'

# view template & form helper
gem 'dynamic_form', '1.1.4'
gem "cells", "~> 3.7.1"
gem 'simple_form', '2.0.2'
gem 'slim', '1.2.2'
gem 'rails_kindeditor', '~> 0.3.9'
gem 'best_in_place', '1.0.6'

# slug generator & different language support
gem "friendly_id", "~> 4.0.1"
gem 'babosa', "~> 0.3.7"

# async job & mail
gem 'sidekiq', '~> 2.5.3'
gem 'premailer-rails3', '1.2.0'

# redis related
gem 'soulmate', '0.1.3'
gem 'em-hiredis', '0.1.1'
gem 'redmon', :require => false

# elasticsearch & tire
gem 'tire', '~> 0.5.1'
gem 'tire-contrib', "~> 0.1.1"

# schedule
gem 'whenever', '0.7.3'

# paginate
gem 'kaminari', '0.13.0'
gem 'will_paginate',  '~> 3.0.2'  # used to required by refinerycms-core

# payment
gem 'activemerchant', '1.28', :require => 'active_merchant'
gem 'am_alipay', '0.0.2', :git => "git://github.com/kenshin54/am_alipay.git"

# I18n
gem 'globalize3', '0.2.0'

# ebay publish
gem 'ebayr', :git => "git://github.com/kenshin54/ebayr.git"

# taobao
gem 'top_notify', '~> 0.0.1', :git => "git://github.com/kenshin54/top_notify.git"
gem 'taobao', :git => 'git://github.com/yonggu/taobao.git'

# other
gem 'sitemap_generator', '3.1.1'
gem 'social-share-button', :git => 'git://github.com/zlx/social-share-button.git', :tag => "0.0.1"
gem "google_drive", "~> 0.3.0"
gem 'awesome_nested_set', '2.1.3'
gem 'exception_notification', '2.6.1'
gem 'state_machine', '1.0.2'
gem 'sinatra', :require => nil
gem 'rack-rewrite', '~> 1.2.1'
gem 'cache_digests', '0.1.0'
gem 'newrelic_rpm', '3.4.2.1'
gem 'turbolinks', '1.0.0'
#gem 'jquery-turbolinks'
gem 'rack-raw-upload', '1.1.0'
gem 'default_value_for', '2.0.1'
gem 'rake_pid', '~> 0.0.1'
gem "unicorn", "~> 4.5.0"
#gem "lazy_high_charts"#, "1.3.3"
gem 'rails-timeago', '~> 2.0'
gem 'jquery_mobile_rails'

group :development do
  gem 'quiet_assets'
  #gem 'better_errors'
  gem "binding_of_caller"
  gem 'thin', '1.3.1'
  gem 'capistrano', '2.12.0'
  gem 'capistrano-ext', '~> 1.2.1'
  gem 'pry-rails'
  #gem 'guard'
  #gem 'guard-livereload'
  #gem 'rb-inotify', :require => false
end

group :test, :development do
  #gem 'debugger', '1.2.0'
  gem 'rspec-rails', '2.10.0'
  gem "rspec-cells", "~> 0.1.2"
  gem 'factory_girl_rails', "~> 3.0"
end

group :test do
  gem 'forgery'#, '0.5.0'
  gem "mocha"#, '0.10.5'
  gem 'spork'#, '~> 1.0rc'
  gem "capybara"#, '~> 2.0.1'
  gem 'xpath'#, '~> 1.0.0'
  gem 'selenium-webdriver'#, '~> 2.0'
  gem "database_cleaner"#, "0.6.7"
  gem "launchy"#, "2.0.5"
  gem "webmock"#, "1.8.9"
  gem "mock_redis"#, "0.6.0"
  gem 'simplecov', :require => false
end

