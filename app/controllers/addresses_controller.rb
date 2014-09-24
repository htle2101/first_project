class AddressesController < ApplicationController
  before_filter :require_user
  before_filter :find_address, :only => [:edit, :update, :destroy]

  def index
    @addresses = current_user.addresses.order('is_default desc')
    @address = current_user.addresses.new
    render :layout => 'checkout'
  end

  def new
    @address = current_user.addresses.new
    render :json => {:address => render_to_string(:partial => 'body', :locals => {:no_add => false})}.to_json
  end

  def create
    @address = current_user.addresses.new(params[:address])
    if request.xhr?
      arr = @address.save ? ['address', true] : ['form', false]
      render :json => {:address => render_to_string(:partial => arr[0]), :status => arr[1]}.to_json
    end
  end

  def edit
    render :json => {:address => render_to_string(:partial => 'body', :locals => {:no_add => true})}.to_json
  end

  def update
    if request.xhr?
      arr = @address.update_attributes(params[:address]) ? ['address', true] : ['form', false]
      render :json => {:address => render_to_string(:partial => arr[0]), :status => arr[1]}.to_json
    end
  end

  def destroy
    @address.destroy
    redirect_to addresses_path
  end

  def change_state
    states = case params[:country_id].to_i
    when Country::USA then Address::US_STATE
    when Country::CANADA then Address::CANADA_STATE
    else nil
    end
    if states.present?
      render :partial => "addresses/state", :locals => {:states => states, :province => nil}
    else
      render :partial => "addresses/state_normal", :locals => {:province => nil}
    end
  end

  private
  def find_address
    @address = current_user.addresses.find(params[:id])
  end

end
