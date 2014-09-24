class FavouritesController < ApplicationController
  before_filter :require_user

  def add
    params[:type] == "Store" ? type_str = "?type=Store" : update_like_count
    params[:type] == "TopicProduct" ? add_product_to_topic : add_element_to_favorite
    render :text => "<a href=#{my_favourites_path}#{type_str}>#{'Go to My Favorites'}</a>"
  end

  private
  def add_product_to_topic
    TopicProduct.find_or_create_by_topic_id_and_taobao_id(params[:fcid], params[:id])
  end

  def add_element_to_favorite
    type = "favourite_#{params[:type].downcase.pluralize}"
    current_user.send(type).find_or_create_by_resource_id(params[:id], :resource_type => params[:type])
  end

  def update_like_count
    product = Util::Importer.import_product(params[:id])
    if product && stat = product.stat
      stat.increment!(:like_count)
    else
      klass = Product.product_model(params[:id], :stat)
      product.stat = klass.create(:like_count => 1)
    end
  end
end
