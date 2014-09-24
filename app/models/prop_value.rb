# coding: utf-8
class PropValue < ActiveRecord::Base
  attr_accessor :img_url
  has_many :categories_prop_values, :primary_key => "vid", :foreign_key => "vid"
  has_many :categories, :through => :categories_prop_values
  belongs_to :item_prop, :foreign_key => "pid", :primary_key => 'pid'
  attr_accessor :name_ru, :name_cn

  translates :name, :slug, :fallbacks_for_empty_translations => true
  include Rails.application.routes.url_helpers
  extend Translator::Base
  include Translator::Import
  include Model::PropValueLib
  extend FriendlyId
  friendly_id :name, :use => [:globalize, :slugged, :scoped], :scope => :pid
  default_scope where{(status == nil) | (status != "deleted")}
  scope :simple, select('id, vid, pid, name, status, url')
  STATUS = {"normal" => "显示", "inactive" => "隐藏", "deleted" => "删除"}

  def prop
    "#{pid}:#{vid}"
  end

  def display?
    ["normal", "active"].include?(self.status)
  end

  def self.import_brands
    $redis.sadd('brands', 'ipad') unless $redis.sismember('brands', 'ipad')
    self.select('id, name').where{pid == 20000}.find_each do |v|
      key = v.name.split('/').select{|a| !a.scan(/^\w[^\u4e00-\u9fa5]*\w$/).blank?}.first.to_s.downcase
      $redis.sadd('brands', key) unless $redis.sismember('brands', key) && key.blank?
    end
  end
end
