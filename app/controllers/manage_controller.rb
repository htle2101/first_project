class ManageController < ApplicationController
  layout 'manage'
  before_filter :require_user
  before_filter :require_admin

  rescue_from CanCan::AccessDenied do
    redirect_to "/404.html"
  end

  def require_admin
    if cannot? :manage, ManageController
      redirect_to "/404.html"
    end
    I18n.locale = 'cn'
  end

  def index
  end
end
