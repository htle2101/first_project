Sidekiq.configure_server do |config|
  unless Rails.env.test?
    config.redis = { :namespace => 'sidekiq'}
  end
end

Sidekiq.configure_client do |config|
  unless Rails.env.test?
    config.redis = { :namespace => 'sidekiq'}
  end
end