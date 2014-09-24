class CartsController < ApplicationController

  def edit
    current_cart.update_attributes(:token => nil, :ship_method_id => nil) if current_cart.try(:token).present?
  end

  def update
    redirect_to addresses_path
  end

  def update_line_item_quantity
    line_item = current_cart.line_items.find_by_id(params[:id])
    render :json => line_item.update_quantity_and_price(params[:quantity]).to_json
  end

  def delete_line_item
    begin
      current_cart.line_items.destroy(params[:id]) if params[:id]
    rescue ActiveRecord::RecordNotFound => e
      logger.info(e)
    end
    render :json => {:status => 1}.to_json
  end

end
