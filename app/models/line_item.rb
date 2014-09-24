class LineItem < ActiveRecord::Base
  belongs_to :cart

  include Model::Share::LineItemAndOrderProduct
  include Util::ModelUtil
  delegate :pv_values, :to => :sku, :allow_nil => true
  delegate :volume, :to => :product, :allow_nil => true
  store :referral_code, accessors: [ :referral_user_id, :referral_enc_id, :referral_agent ]

  def product
    @product ||= Product.tfind(taobao_id)
  end

  delegate :has_sku?, :to => :product

  def sku
    @sku ||= product.skus.find_by_sku_id(sku_id)
  end

  def sku_or_product
    has_sku? ? sku : product
  end

  def original_price
    sku_or_product.original_price(quantity)
  end

  def weight
    (self['weight'] || self.product.weight).to_f
  end

  alias :referral_affiliate_id :referral_user_id
  def referral_user_id
    @referral_user_id ||= referral_user.try(:id)
  end

  def referral_user
    @referral_user ||= self.referral_affiliate_id && User.find_by_affiliate_id(self.referral_affiliate_id)
  end

  def update_quantity_and_price(quantity)
    quantity = sku_or_product.valid_quantity(quantity.to_i)
    price = sku_or_product.bc_price(quantity)
    if update_attributes(:quantity => quantity, :price => price)
      { :status => 1, :quantity => quantity, :price => price, :original_price => sku_or_product.original_price(quantity) }
    else
      { :status => 0 }
    end
  end
end
