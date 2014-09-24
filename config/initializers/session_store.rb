# Be sure to restart your server when you modify this file.

if Rails.env.production? || Rails.env.staging?
  BuyChina::Application.config.session_store :cookie_store, key: '_buychina_session', :domain => :all
else
  BuyChina::Application.config.session_store :cookie_store, key: '_buychina_session'
end

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rails generate session_migration")
# BuyChina::Application.config.session_store :active_record_store
