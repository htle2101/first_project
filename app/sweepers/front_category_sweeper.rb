class FrontCategorySweeper < ActionController::Caching::Sweeper
  observe FrontCategory

  def after_create(front_category)
    expire_cache(front_category)
  end

  def after_update(front_category)
    expire_cache(front_category)
  end

  def after_destroy(front_category)
    expire_cache(front_category)
  end

  def expire_cache(fc)
    ['en', 'ru', 'cn'].each{ |str| expire_fragment("home_categories_#{str}") }
    Util::Common::URL_PREFIX.each do |key, value|
      expire_page "#{value}#{fc.url}"
    end
  end
end
