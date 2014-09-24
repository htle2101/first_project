class ReviewsController < ApplicationController
  def add
    ProductFeedback.find(params[:id]).increment!(:usefulness)
    render :text => true
  end
end