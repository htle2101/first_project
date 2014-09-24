class BrandsController < ApplicationController 
  include Controller::ShareManage
  before_filter :get_brand, :only => :show
  before_filter :initialize_search, :only => :show
  def index
    @categories = Category.brand_categories
  end

  def show
    default_process
    correct_params("#{@brand.pid}:#{@brand.vid}")
    render "products/index"
  end

  private
  def get_brand
    @brand = Brand.find(params[:id])
    params[:props] = "#{@brand.pid}:#{@brand.vid};" + params[:props].to_s
    params.delete("id")
  end
  
  def category
    super(false)
  end
end
