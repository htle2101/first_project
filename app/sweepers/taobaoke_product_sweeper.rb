class TaobaokeProductSweeper < ActionController::Caching::Sweeper
  observe TaobaokeProduct

  def after_save(tp)
    fcid = tp.changes['fcid'] ? (tp.changes['fcid'][0] || tp.changes['fcid'][1]) : tp.fcid
    expire_cache(fcid) if fcid && fcid != 0
  end

  def expire_cache(fcid)
    topic = FrontCategory.find_by_id(fcid)
    if topic && !topic.is_front_category?
      Util::Common::URL_PREFIX.each do |key, value|
        expire_page "#{value}#{topic.url(key)}"
      end
    end
  end
end
