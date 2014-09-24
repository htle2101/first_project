class Cart < ActiveRecord::Base
  belongs_to :user
  has_many :line_items, :extend => ::Association::LineItemExtension
  belongs_to :address

  def add_item(product, sku_id, quantity, referral_code = {})
    return if product.nil?
    return if product.has_sku? && (sku_id.blank? || (sku = product.skus.find_by_sku_id(sku_id)).blank?)
    sku_id = nil if sku_id.blank?
    sku_or_product = sku || product
    return if quantity == 0
    quantity = sku_or_product.valid_quantity(quantity)
    attrs = sku.present? ? { :sku_id => sku.sku_id, :pv_values => sku.pv_values } : {}
    attrs.merge!(:quantity => quantity, :price => sku_or_product.bc_price(quantity)).merge!(referral_code)
    if item = line_items.find_by_taobao_id_and_sku_id(product.taobao_id, sku_id)
      item.update_attributes(attrs)
    else
      item = line_items.create(attrs.merge(:product_id => product.id, :taobao_id => product.taobao_id, :store_id => product.store_id))
    end
    item
  end

  def buy_now(product, sku_id, quantity, ship_method_id, referral_code = {})
    item = add_item(product, sku_id, quantity, referral_code)
    attrs = {:ship_method_id => ship_method_id}
    if item.present? && product.weight.present?
      token = rand(36**10).to_s(36)
      item.update_attributes(:weight => product.weight, :token => token)
      attrs.merge!(:token => token)
    end
    self.update_attributes(attrs)
    token
  end

  def merge_cart(current_cart)
    current_cart.line_items.each do |item|
      if citem = self.line_items.find_by_product_id_and_sku_id(item.product_id, item.sku_id)
        citem.update_attributes({
          :quantity => item.quantity, :price => item.price, :weight => item.weight, :note => item.note})
          item.delete
      else
        item.update_attributes :cart_id => self.id
      end
    end
    self.update_attributes(:address_id => current_cart.address_id, :ship_method_id => current_cart.ship_method_id, :token => current_cart.token, :last_country_id => current_cart.last_country_id)
    current_cart.destroy
    self.id
  end

  def weight
    self.line_items.weight
  end

  def weight_and_compare
    weight, c_volume, c_weight = 0, 0, 0
    self.line_items.each do |item|
      if item.volume > 0
        c_volume += item.volume * item.quantity
        c_weight += item.weight * item.quantity
      else
        weight += item.weight * item.quantity
      end
    end
    {:weight => weight / 1000, :compare => {:weight => c_weight / 1000, :volume => c_volume}}
  end

  def ship_method
    ExpressCal::Cost::SHIP_METHOD[self.ship_method_id][:name]
  end

  def ship_price
    shipping_method.try(:cost).to_f
  end

  def shipping_method
    shipping_methods.detect {|sm| sm.ship_id == self.ship_method_id}
  end

  def sub_total
    self.ship_price + self.line_items.sub_total
  end

  def create_order(params)
    order = build_order
    order.order_products = self.line_items.inject([]) do |ops, item|
      ops << build_order_product(item, params)
    end
    order.order_address = OrderAddress.new(self.address.as_json.delete_if{|key| key =~ /ated_at/})
    Order.transaction do
      order.save
      buy_now_item? ? self.line_items.destroy_all : self.destroy
    end
    order
  end

  def shipping_methods
    ops = {:country => address.country, :price => line_items.sub_total}.merge(weight_and_compare)
    @asms ||= ExpressCal::Cost.shipping_methods(ops)
  end

  alias :origin_line_items :line_items

  def line_items_by_token
    self.token.present? ? origin_line_items.where(:token => self.token) : []
  end

  def line_items
    @line_items ||= (self.token.present? ? line_items_by_token : origin_line_items)
  end

  def buy_now_item?
    self.line_items.count == 1 && self.line_items.first.token.present?
  end

  private
  def build_order
    attrs = {
      :sub_total => self.line_items.sub_total.roundf, :shipping_cost => self.ship_price.roundf, 
      :country_id => self.last_country_id, :ship_method_id => self.ship_method_id,
      :user_id => user.id, :user_name => user.username, :ip_address => user.current_sign_in_ip, :locale => I18n.locale
    }
    Order.new(attrs)
  end

  def build_order_product(item, params)
    attrs = {
      :product_id => item.product_id, :taobao_id => item.product.taobao_id,
      :store_id => item.store_id, :store_name => item.product.store_name,
      :name => item.product.name, :pic_url => item.product.pic_url,
      :sku_id => item.sku_id, :pv_values => item.pv_values, :quantity => item.quantity,
      :price => item.price, :weight => item.weight, :comment => params["comment#{item.id}".to_sym]
    }
    attrs.merge!(:original_price => item.original_price) if item.product.on_promotion?
    op = OrderProduct.new(attrs)
    build_referral_product(op, item)
    op
  end

  def build_referral_product(order_product, item)
    unless user.is_self_referral?(item)
      attrs = {:referral_user_id => item.referral_user_id, :referral_user_name => item.referral_user.try(:username), 
               :referral_agent => item.referral_agent, :buyer_id => user.id}
      order_product.build_referral_product(attrs)
    end
  end
end
