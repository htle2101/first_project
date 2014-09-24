class MyController < ApplicationController
  layout 'my'

  before_filter :require_user

  def index

  end

  def resend_confirm
    Devise::Mailer.delay.confirmation_instructions(current_user)
    render :json => {:sended => true}
  end

end
