# coding: utf-8
class Product < ActiveRecord::Base
  has_one :stat, :class_name => "ProductStat", :primary_key => :taobao_id, :foreign_key => :taobao_id
  has_one :detail, :class_name => "ProductDetail", :dependent => :destroy
  has_many :images, :class_name => "ProductImage", :dependent => :destroy
  has_many :skus, :class_name => "ProductSku", :dependent => :destroy
  has_many :prop_aliases, :dependent => :destroy
  belongs_to :store
  belongs_to :category, :foreign_key => :cid, :primary_key => :cid
  has_many :favourites, :as => :resource
  has_many :users, :through => :favourites
  delegate :shop_link, :to => :store, :prefix => true, :allow_nil => true
  has_many :product_feedbacks, :foreign_key => :taobao_id, :primary_key => :taobao_id
  has_one :promotion, :class_name => "ProductPromotion", :foreign_key => :taobao_id, :primary_key => :taobao_id

  include Tire::Model::Search
  include Tire::Model::Callbacks

  include Model::ProductLib
  include Util::ImageVersion
  include Model::Share::ProductAndSku
  extend Util::ModelUtil
  include Util::Cache

  accepts_nested_attributes_for :detail, :allow_destroy => true
  accepts_nested_attributes_for :skus, :allow_destroy => true

  translates :name, :fallbacks_for_empty_translations => true
  extend FriendlyId
  friendly_id :name_and_taobao_id, :use => :slugged
  include Translator::Import
  image_attr :pic_url
  document_type 'product'
end
