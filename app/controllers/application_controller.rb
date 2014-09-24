class ApplicationController < ActionController::Base
  helper_method :current_cart, :find_or_create_cart, :redis, :render_404

  protect_from_forgery

  include SimpleCaptcha::ControllerHelpers
  include Util::ModelUtil

  before_filter :store_location, :set_locale, :affiliate_link_check, :set_current_user

  around_filter :show_process_name_from_request if Rails.env.production?

  def set_locale
    session[:locale] = params[:locale] if params[:locale]
    session[:locale] = subdomain_country if subdomain_country
    I18n.locale = session[:locale] || I18n.default_locale
  end

  def affiliate_link_check
    if params[:r]
      cookies[:referral_code] = {
        :value => {
          :referral_user_id => params[:r],
          :referral_agent => ReferralProduct::REFERRAL_AGENT[params[:ragent].to_s.to_sym].to_i,
          :referral_enc_id => params[:id][/\w+$/]
        }.to_json, :expires => 15.days.from_now }
      Referral.delay.save_referral_click(params, request.remote_ip, request.referer)
    end
  end


  def show_welcome_page?
    false
  end

  def current_cart
    return @current_cart if @current_cart
    if session[:cart_id]
      begin
        return @current_cart = Cart.find(session[:cart_id])
      rescue
        return user_cart_or_nil
      end
    else
      user_cart_or_nil
    end
  end

  def user_cart_or_nil
    if current_user && current_user.cart
      @current_cart = current_user.cart
      session[:cart_id] = @current_cart.id
      @current_cart
    else
      nil
    end
  end

  def find_or_create_cart
    if current_cart.nil?
      @current_cart = Cart.create(:user_id => current_user.try(:id))
      session[:cart_id] = @current_cart.id
      @current_cart
    else
      current_cart
    end
  end

  def combine_line_items
    if current_cart && current_user.try(:cart)
      session[:cart_id] = current_user.cart.merge_cart(current_cart) unless current_cart == current_user.cart
    elsif current_user.try(:cart)
      session[:cart_id] = current_user.cart.id
    elsif current_cart
      current_cart.update_attribute(:user_id, current_user.id)
    end
  end

  def back_or_default_url(default)
    back_url = session[:return_to]
    session[:return_to] = nil
    back_url || default
  end

  def store_location
    # disallow return to login, logout, signup pages
    disallowed_urls = [main_app.signup_path, main_app.login_path, main_app.logout_path, main_app.affiliate_home_index_path]
    if !disallowed_urls.include?(request.fullpath) && !request.xhr?
      session[:return_to] = request.fullpath
    end
  end

  def require_user
    unless current_user
      store_location
      flash[:notice] = I18n.t("page_only_viewable_when_logged_in")
      request.xhr? ? render(:text => "login") : redirect_to(login_path)
      return false
    end
  end

  def require_no_user
    if current_user
      store_location
      flash[:notice] = I18n.t("page_only_viewable_when_logged_out")
      redirect_to root_url
      return false
    end
  end

  def redis
    @redis ||= Redis.new
  end


  def subdomain_country
    if request.subdomain.present? && ['www', 'cn', 'ru'].include?(request.subdomain)
      request.subdomain == "www" ? "en" : request.subdomain
    end
  end

  def set_current_user
    User.current = current_user
  end

  def render_404
    render "home/not_found", :status => 404
  end

  def show_process_name_from_request
    process = "Rack #{request.remote_ip} - #{request.path[0, 70]}"
    $0 = process
    yield
    $0 = process << "*"
  end

end
