require 'will_paginate/array'
class FrontCategoriesController < ApplicationController
  before_filter :get_front_category, :only => [:front_categories, :topics, :brands, :ajax_get_products, :promotions]
  def front_categories
  end

  def topics
  end

  def brands
  end

  def promotions
  end

  def template
    case @front_category.template
    when 1 then template_promotion
    when 2 then template_cascade
    when 3, nil then template_class
    when 4 then template_topic
    when 5 then template_cosplay
    end
  end

  def template_promotion
    render 'template_promotion'
  end

  def ajax_get_products
    params[:page_no] = ((params[:page] || 1).to_i - 1) * 5 + params[:page_no].to_i
    @products = if @front_category.categories.first
      @front_category.search({:page_no => params[:page_no]}, {:fcid => params[:fcid], :cid => params[:cid]}).results
    else
      @front_category.tproducts.paginate(:page => params[:page_no], :per_page => 32)
    end
    render :layout => false
  end

  def template_cascade
    @path = @front_category.url
    quantity = @front_category.instance_eval{categories.first ? search({}).total : tproducts.count}
    @total_pages = (quantity / 32.0).ceil
    pages = (quantity / 160.0).ceil
    @pages = (1..pages).to_a.paginate(:page => params[:page] || 1, :per_page => 1)
    render 'template_cascade'
  end

  def template_topic
    render 'template_topic'
  end

  def template_class
    @children = if @front_category.children.present?
      @front_category.children
    else
      @tproducts = @front_category.products.paginate(:page => params[:page], :per_page => 32)
      @front_category.parent.children
    end
    render 'template_class'
  end

  def template_cosplay
    render 'template_cosplay'
  end

  private

  def get_front_category
    slug = params[:topic] || params[:id] || params[:slug]
    @front_category = FrontCategory.send(params[:type] || action_name).find(slug)
    template unless request.xhr?
  end
end
