require "babosa"

FriendlyId.defaults do |config|
  config.base = :name
  config.use :slugged
  config.use Module.new {
    def normalize_friendly_id(text)
      text.to_s.to_slug.normalize(:transliterations => [:russian, :latin]).to_s
    end
  }
end
