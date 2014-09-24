class PagesController < ApplicationController
  layout "help"

  def index
    @top_pages = Page.tops
    @top_helps = PageType.help_root.where("image is not NULL and alias is not NULL")
  end

  def common
    @common_pages = Page.commons
    @page = Page.commons.find(params[:id])
  end

  def show
    @page = Page.find(params[:id])
  end

  def page_type
    @page_type = PageType.find(params[:id])
  end

  def feedback
    page = Page.find(params[:id])
    page.increment(params[:feedback]=='1' ? :up : :down)
    page.save
    render :nothing => true
  end

  def shipping
    @countries = Country.all #with_out_china
    country = Country.find_by_id(params[:country_id]) || Country.usa
    @weight = (params[:weight] || 500).to_f
    @asms = ExpressCal::Cost.shipping_methods({:country => country, :price => 0, :weight => @weight / 1000})
    request.xhr? ? render(:partial => "shipping_methods") : render('shipping')
  end

end
