class HomeController < ApplicationController
  def index
    init_modules(:published)
  end

  def update_captcha
    render :partial => 'simple_captcha/update_captcha'
  end

  def verify_captcha
    render :text => simple_captcha_valid?
  end

  def sign
    render :partial => "/shared/sign", :locals => {:user => User.new}
  end

  def autocomplete_keywords
    render :json => SearchKey.auto_search(params[:term])
  end

  def not_found
    render :status => 404
  end

  def error
    render 'not_found', :status => 500
  end

  def front_modules
    init_modules(:preview)
    render "index"
  end

  def suggest
    if params[:keyword].blank? || Rails.env.staging?
      render :json => []
    else
      args = case I18n.locale
      when :cn then {:suffix => 'cn', :mkt => 3240}
      else {:suffix => 'com', :mkt => 1}
      end
      resp = RestClient.get("http://completion.amazon.#{args[:suffix]}/search/complete",
                            {:params => {:q => params[:keyword], 'search-alias' => 'aps', :mkt => args[:mkt]}})
      render :json => ActiveSupport::JSON.decode(resp)[1]
    end
  end

  private
  def init_modules(type)
    @front_modules = FrontModule.get_modules(I18n.locale, :main, type)
    @left_modules = FrontModule.get_modules(I18n.locale, :left_bar, type)
    @single_item = FrontModule.send(type).deals.first
    @big_promotion = FrontCategory.big_promotion
    @small_promotion = FrontCategory.small_promotion
    @guides = Guide.order('updated_at DESC').first(6)
  end
end
