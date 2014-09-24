class CrawlLog < ActiveRecord::Base

  TYPE = {
    :seller => 1,
    :keyword => 2,
    :category => 3,
    :tag => 4
  }

  STATUS = {
    :waiting => 0,
    :finish => 1
  }

  validates_presence_of :key, :crawl_type
  validates_inclusion_of :crawl_type, :in => TYPE.values
  validates_format_of :key, :with => /http.*com\\?/,
    :if => Proc.new { |crawl_log| crawl_log.crawl_type == TYPE[:seller] }, :message => "url is not valid"

  after_create :add_to_redis
  after_update :remove_old_and_add_new_to_redis
  after_destroy :remove_from_redis

  TYPE.each_pair do |k, v|
    scope k, where(:crawl_type => v)
  end

  STATUS.each_pair do |k, v|
    scope k, where(:status => v)
  end

  attr_accessor :old_key, :old_crawl_type

  class << self
    def add_to_crawl(type, import_to_redis = false, list)
      return unless TYPE.values.include?(type)
      list.each do |key|
        unless exists?(:key => key, :crawl_type => type)
          create(:key => key, :crawl_type => type)
        end
      end
    end

  end

  def redis
    @redis ||= Redis.new
  end

  def waiting?
    self.status == STATUS[:waiting]
  end

  def add_to_redis
    redis.sadd(redis_key(self.crawl_type), self.key)
  end

  def remove_from_redis
    redis.srem(redis_key(self.crawl_type), self.key)
  end

  def remove_old_and_add_new_to_redis
    if self.changed_attributes.include?("key") || self.changed_attributes.include?("crawl_type")
      redis.srem(redis_key(self.changed_attributes["crawl_type"] || self.crawl_type),
                 self.changed_attributes["key"] || self.key)
      self.add_to_redis
    end
  end

  def redis_key(type)
    "Crawl::#{TYPE.invert[type].to_s.capitalize}::WAITING".constantize
  end

end
