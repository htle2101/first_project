require 'rubygems'
require 'spork'
require 'simplecov'
require 'webmock/rspec'
#uncomment the following line to use spork with the debugger
#require 'spork/ext/ruby-debug'
SimpleCov.start 'rails'

Spork.prefork do
  # Loading more in this block will cause your tests to run faster. However,
  # if you change any configuration or code from libraries loaded here, you'll
  # need to restart spork for it take effect.

  # This file is copied to spec/ when you run 'rails generate rspec:install'
  ENV["RAILS_ENV"] ||= 'test'
  require File.expand_path("../../config/environment", __FILE__)
  require 'rspec/rails'
  require 'rspec/autorun'
  require 'capybara/rspec'

  # Requires supporting ruby files with custom matchers and macros, etc,
  # in spec/support/ and its subdirectories.
  Dir[Rails.root.join("spec/support/**/*.rb")].each {|f| require f}
  Dir[Rails.root.join("app/models/*.rb")].each do |f|
    klass = File.basename(f, ".rb").camelize.constantize
    klass.publicize_methods if klass.respond_to?(:publicize_methods)
  end

  #Capybara.javascript_driver = :webkit
  #Capybara.server_port = 3003
  #Capybara.server_boot_timeout = 50
  #Capybara.register_driver :selenium do |app|
    #Capybara::Selenium::Driver.new(app, :browser => :chrome)
  #end

  RSpec.configure do |config|
    #config.include Devise::TestHelpers
    config.extend ControllerMacros
    # ## Mock Framework
    #
    # If you prefer to use mocha, flexmock or RR, uncomment the appropriate line:
    #
    # config.mock_with :mocha
    # config.mock_with :flexmock
    # config.mock_with :rr

    # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
    config.include FactoryGirl::Syntax::Methods

    # access to use route helpers
    config.include Rails.application.routes.url_helpers

    # If you're not using ActiveRecord, or you'd prefer not to run each of your
    # examples within a transaction, remove the following line or assign false
    # instead of true.
    config.use_transactional_fixtures = true

    # If true, the base class of anonymous controllers will be inferred
    # automatically. This will be the default behavior in future versions of
    # rspec-rails.
    config.infer_base_class_for_anonymous_controllers = false
    config.before(:all) do
      ActiveRecord::Base.observers.disable :all
    end

    config.before(:each) do
      stub_request(:any, %r|http://localhost:9200/.*|).to_return(:status => 200, :body => "{}", :headers => {})
      redis_instance = MockRedis.new
      Redis.stubs(:new).returns(redis_instance)
      $redis = redis_instance

      stub_request(:get, %r|http://127.0.0.1.*|).
         with(:headers => {'Accept'=>'*/*', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'User-Agent'=>'Ruby'}).
         to_return(:status => 200, :body => "", :headers => {})
    end

  end

end



Spork.each_run do
  # This code will be run each time you run your specs.
  FactoryGirl.reload
end

