require 'spec_helper'

describe Cart do
  before do
    @c = create(:cart_with_item_random)
    @stub_shipping_methods = \
      [ShippingMethod.new(:ship_id => 0, :cost => 10),
        ShippingMethod.new(:ship_id => 1, :cost => 20)]
  end

  context "#add_item" do

    it "should return nil" do
      @c.add_item(nil,nil,nil).should be_nil

      product = create(:product_with_sku, :num => 11)
      sku = create(:product_sku_random, :product_id => 2)
      @c.add_item(product, nil, nil).should be_nil
      @c.add_item(product, sku, nil).should be_nil

      product_sku = create(:product_sku_random, :product_id => 11)
      @c.add_item(product, product_sku, 0).should be_nil
    end

    it "should return new item" do
      product = create(:product)
      item = @c.add_item(product, nil, 10)

      item.product_id.should eq(product.id)
      item.taobao_id.should eq(product.taobao_id)
      item.store_id.should eq(product.store_id)
      item.price.should eq(product.bc_price(10))
      item.quantity.should eq(10)
    end

    it "should return exist item" do
      sku_id = 10
      taobao_id = 100
      @c = create(:cart_with_item, sku_id: sku_id, taobao_id: taobao_id)
      product = create(:product_with_sku, taobao_id: taobao_id, sku_id: sku_id)
      sku = ProductSku.find_by_sku_id(sku_id)

      item = @c.add_item(product, sku_id, 10)
      item.pv_values.should eq(sku.pv_values)
      item.sku_id.should eq(sku_id)
      item.price.should eq(sku.bc_price(10))
      item.quantity.should eq(10)
    end
  end

  context "#buy_now" do
    before do
      @product_with_nil_weight = create(:product)
      @product = create(:product, :id => 2, :taobao_id => 987654321)
      @product.stub(:weight => 20)
      @product_with_nil_weight.stub(:weight => nil)
    end

    it "should return nil" do
      @c.stub(:add_item => nil)

      # item: nil and product.weight: not nil
      @c.buy_now(@product, 10, 100, 2).should be_nil

      @c.stub(:add_item => create(:line_item))
      # item: not nil and product.weight: nil
      @c.buy_now(@product_with_nil_weight, 10, 100, 2).should be_nil

      # item: nil and product.weight: nil
      @c.buy_now(@product_with_nil_weight, 10, 100, 2).should be_nil
    end

    it "should return token" do

      item = create(:line_item)
      @c.stub(:add_item => item)
      @c.stub(:rand => 2731516182408789)
      token = @c.buy_now(@product, 10, 100, 2)

      token.should eq("qw8p7lcjf9")

      # check cart attributes
      @c.ship_method_id.should eq(2)
      @c.token.should eq(token)

      # check item attribute
      item.weight.should eq(20)
      item.token.should eq(token)
    end
  end

  context "#merge_cart" do
    before do
      @current_cart = create(:cart_with_item_random)
      @line_items = @current_cart.origin_line_items
      @current_cart.stub(:line_items => @current_cart.origin_line_items)
    end

    it "needn't merge the same item" do

      @c.merge_cart(@current_cart)

      @line_items.each do |item|
        @line_items.map(&:id).should include(item.id)
      end

      check_attributes
    end

    it "need merge item" do
      @c = create(:cart_with_item_random)
      @c.stub(:line_items => @c.origin_line_items)
      @c.merge_cart(@current_cart)

      @line_items.each do |item|
        citem = @c.line_items
        .find_by_product_id_and_sku_id(item.product_id, item.sku_id)

        citem.quantity.should eq(item.quantity)
        citem.price.should eq(item.price)
        citem.weight.should eq(item.weight)
        citem.note.should eq(item.note)
      end
      check_attributes
    end

    def check_attributes
      @c.address_id.should eq(@current_cart.address_id)
      @c.ship_method_id.should eq(@current_cart.ship_method_id)
      @c.token.should eq(@current_cart.token)
      @c.last_country_id.should eq(@current_cart.last_country_id)
    end
  end

  it "#weight" do
    @c = create(:cart_with_item)
    @c.weight.should \
      eq(@c.line_items.inject(0){|sum, item| sum += item.total_weight}/1000)
  end

  it "#ship_method" do
    @c.ship_method.should \
      eq(ExpressCal::Cost::SHIP_METHOD[@c.ship_method_id][:name])
  end

  context "#shipping_methods" do
    it "#shipping_methods" do
      ExpressCal::Cost.stub(:shipping_methods => @stub_shipping_methods)
      @c = create(:cart_with_address)
      @c.instance_eval do
        @asms = nil
      end
      shipping_methods_fields(@c.shipping_methods).should \
        eq(shipping_methods_fields(@stub_shipping_methods))

      @c.instance_eval do
        @asms = \
          [ShippingMethod.new(:ship_id => 0, :cost => 10),
            ShippingMethod.new(:ship_id => 1, :cost => 20)]
      end
      shipping_methods_fields(@c.shipping_methods).should \
        eq(shipping_methods_fields(@stub_shipping_methods))
    end

    def shipping_methods_fields(shipping_methods)
      shipping_methods.collect{|m| [m.ship_id, m.cost]}
    end
  end


  it "#ship_price" do
    @c.stub(:shipping_methods => @stub_shipping_methods)
    @c.ship_price.should eq(@c.shipping_method.try(:cost).to_f)
  end

  it "#shipping_method" do
    @c.stub(:shipping_methods => @stub_shipping_methods)
    @c.shipping_method.should \
      eq(@c.shipping_methods.detect {|sm| sm.ship_id == @c.ship_method_id})
  end

  it "#sub_total" do
    @c.stub(:shipping_methods => @stub_shipping_methods)
    @c.sub_total.should \
      eq(@c.ship_price + @c.line_items.sub_total)

  end
  context  "#create_order" do
    before do
      @c = create(:cart_with_user)
      @c.stub(:shipping_methods => @stub_shipping_methods)
      @c.stub(:line_items => @c.origin_line_items)
    end

    it "#build_order" do
      u = @c.user
      order = @c.build_order

      order.should be_new_record
      "#{order.number}".length.should == 8
      order.sub_total.should eq(@c.line_items.sub_total)
      order.origin_price.should eq(@c.line_items.sub_total)
      order.shipping_cost.should eq(@c.ship_price)
      order.discount.should == 0.0
      order.user_id.should eq(u.id)
      order.user_name.should eq(u.username)
      order.country_id.should eq(@c.last_country_id)
      order.ship_method_id.should eq(@c.ship_method_id)
      order.status.should eq(Order::ORDER_STATUS['WAITING'])
      order.ip_address.should eq(u.current_sign_in_ip)
      order.locale.should eq(I18n.locale)
    end

    it "#build_order_product" do
      item = @c.line_items.first
      product = create(:product)
      item.stub(:product => product)
      params = {"comment#{item.id}".to_sym => "comment"}
      op = @c.build_order_product(item, params)

      op.should be_new_record
      op.product_id.should eq(item.product_id)
      op.taobao_id.should eq(item.product.taobao_id)
      op.store_id.should eq(item.store_id)
      op.store_name.should eq(item.product.store_name)
      op.name.should eq(item.product.name)
      op.pic_url.should eq(item.product.pic_url)
      op.sku_id.should eq(item.sku_id)
      op.pv_values.should eq(item.pv_values)
      op.quantity.should eq(item.quantity)
      op.price.should eq(item.price)
      op.weight.should eq(item.weight)
      op.comment.should eq("comment")
    end

    it "#buy_now_item" do
      params, line_items = prepare
      @c.stub("buy_now_item?" => true)
      order = @c.create_order(params)
      @c.line_items.should eq([])
      check_order_address_and_products(order, line_items)
    end

    it "#normal buy" do
      params, line_items = prepare
      @c.stub("buy_now_item?" => false)
      order = @c.create_order(params)
      Cart.find_by_id(@c.id).should be_nil
      check_order_address_and_products(order, line_items)
    end

    def prepare
      params = {}
      line_items = @c.line_items.dup
      line_items.each do |item|
        params["comment#{item.id}".to_sym] = "comment#{item.id}"
      end
      return params, line_items
    end

    def check_order_address_and_products(order, line_items)
      @c.address.as_json.delete_if{|key| key=~ /ated_at/}.each do |key, value|
        address = order.order_address.as_json
        value.should eq(address[key]) if key != "id"
      end
      order.order_products.size.should eq(line_items.size)
    end

  end

  it "#buy_now_item?" do
    @c.stub(:line_items => @c.origin_line_items)
    @c.should_not be_buy_now_item
  end

  it "#line_items_by_token" do
    @c.line_items_by_token.should eq([])

    @c = create(:cart_with_item, :token => nil)
    @c.line_items_by_token.should eq([])

    @c = create(:cart_with_item_token_match)
    @c.line_items_by_token.should \
      eq(@c.origin_line_items.where(:token => @c.token))
  end

  context "#line_items" do
    it "should return @line_items" do
      @c.instance_eval do
        @line_items = ["test"]
      end
      @c.line_items.should eq(["test"])
    end

    it "should call line_items_by_token" do
      @c.line_items.should eq(@c.line_items_by_token)
    end

    it "should call origin_line_items" do
      @c = create(:cart_with_item, :token => nil)
      @c.line_items.should eq(@c.origin_line_items)
    end
  end
end
