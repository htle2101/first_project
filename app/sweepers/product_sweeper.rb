class ProductSweeper < ActionController::Caching::Sweeper
  product_models = Rails.configuration.pgr.inject('Product'){ |result, str| result += ",Product#{str}"}
  eval("observe #{product_models}")
  
  def after_update(product)
    expire_cache(product)
  end

  def after_destroy(product)
    expire_cache(product)
  end

  private
  def expire_cache(product)
    Util::Common::URL_PREFIX.each do |key, value|
      expire_action "#{value}#{product_path(product.slug)}"
    end
  end
end
