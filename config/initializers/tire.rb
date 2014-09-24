Tire.configure do
  mapping_to_create_index(true) if Rails.env.production? || Rails.env.staging?
  logger 'log/elasticsearch.log'
  url 'http://xxx.xxx.xxx.xxx:9200' if Rails.env.production?
end
