require 'spec_helper'

describe LineItem do
  before do
    @product = create(:product_with_sku, :taobao_id => 200000)
    @line_item = create(:line_item, :product_id => @product.id, :taobao_id => @product.taobao_id, :sku_id => @product.skus.first.sku_id, :weight => 2.0 )
  end
  it "should return the proper product" do
    @line_item.product.should == @product
  end

  it "should return the proper sku" do
    @line_item.sku.should == @product.skus.find_by_sku_id(@line_item.sku_id)
  end

  it "should return proper weight" do
    @line_item.weight.should == 2.0
  end

  context "#sku_or_product" do
    it "should return sku when sku and product all available" do
      @line_item.sku_or_product.should == @line_item.sku
    end
    it "should return product when product available but sku unavailable" do
      @line_item.stub(:has_sku? => false)
      @line_item.sku_or_product.should == @product
    end
  end

  it "should return original_price from sku_or_product" do
    @line_item.stub_chain(:sku_or_product, :original_price => 10)
    @line_item.original_price.should == 10
  end

  context "update_quantity_and_price" do
    before do
      @line_item.stub_chain(:sku_or_product, :valid_quantity => 1)
      @line_item.stub_chain(:sku_or_product, :bc_price => 10)
      @line_item.stub_chain(:sku_or_product, :original_price => 10)
    end
    it "should return status with 1 when update successfully" do
      @line_item.update_quantity_and_price(1).should == {:status => 1,:quantity => 1, :price => 10, :original_price => 10}
    end
    it "should return status with 0 when update fail" do
      @line_item.stub(:update_attributes => false)
      @line_item.update_quantity_and_price(1).should == {:status => 0}
    end
  end

end
