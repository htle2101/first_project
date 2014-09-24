require File.expand_path('../boot', __FILE__)

require 'rails/all'

if defined?(Bundler)
  # If you precompile assets before deploying to production, use this line
  Bundler.require(*Rails.groups(:assets => %w(development test)))
  # If you want your assets lazily compiled in production, use this line
  # Bundler.require(:default, :assets, Rails.env)
end

module BuyChina
  class Application < Rails::Application
    config.eager_load_paths += %W(#{config.root}/lib/util)
    config.autoload_paths += %W(#{config.root}/lib #{config.root}/app/sweepers)
    config.before_initialize do
      require 'init'
    end

    config.to_prepare do
      Devise::Mailer.layout "mail"
      [
        Model::ProductLib, Model::ProductImageLib, Model::ProductSkuLib,
        Model::ProductDetailLib, Model::PropAliasLib, Model::ProductStatLib
      ].each do |klass| klass.generate(TOPLEVEL_BINDING)
      end
    end

    config.after_initialize do

      ActiveMerchant::Billing::Integrations::Alipay.configure do |conf|
        conf.pid = APP_CONFIG[:alipay_pid]
        conf.key = APP_CONFIG[:alipay_key]
        conf.user_agent = "Buychina -- http://www.buychina.com"
      end

      require 'active_merchant/billing/integrations/action_view_helper'
      ActionView::Base.send(:include, ActiveMerchant::Billing::Integrations::ActionViewHelper)

      ::PRODUCTS = config.pgr.to_a.insert(0, "").map do |i|
        "Product#{i}".constantize
      end

    end

    config.active_record.observers = :orderlog_observer

    config.i18n.load_path += Dir[Rails.root.join('config', 'locales', '**', '*.{rb,yml}').to_s]

    config.encoding = "utf-8"

    config.filter_parameters += [:password]

    config.assets.enabled = true
    config.assets.version = '1.0'

    config.exceptions_app = self.routes

    # OPTIMIZE
    config.action_mailer.delivery_method = :smtp

    config.i18n.fallbacks = true

    #product_generate_range
    config.pgr = (1..19)
    config.middleware.use 'Rack::RawUpload'
  end # Application
end
