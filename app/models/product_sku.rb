class ProductSku < ActiveRecord::Base
  belongs_to :product
  include Model::Share::ProductAndSku

  include Model::ProductSkuLib
  attr_accessor :to_taobao_price, :taobao_id
  before_update :get_new_taobao_price
  delegate :on_promotion?, :promotion, :to => :product, :allow_nil => true
  scope :can_sale, where("stock_num > 0")
end
