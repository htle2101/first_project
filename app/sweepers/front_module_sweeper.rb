class FrontModuleSweeper < ActionController::Caching::Sweeper
  observe FrontModule

  def after_update(front_module)
    expire_cache(front_module)
  end

  def after_destroy(front_module)
    expire_cache(front_module)
  end

  private
  def expire_cache(fm)
    ['en', 'ru', 'cn'].each { |locale| expire_fragment("fm_#{fm.id}_#{locale}") }
  end
end
