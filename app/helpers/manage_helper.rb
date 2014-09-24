#encoding: UTF-8
module ManageHelper
  def status(status)
    Order.status_cn(status)
  end

  def tao_status(status)
    ts = PurchaseProduct::TS
    if status.nil?
      ts.invert[0]
    else
      ts.invert[status]
    end
  end

  # fixed tab for post request when switch
  def fixed_tab(name, link, current_id, current_query, default = false)
    %Q{<li class="#{(current_id == current_query || default&&!current_query) ? 'active' : ''}" > <a id="#{current_id}" href="#{link}">#{name}</a></li>}
  end

  def order_status_amount(options)
    @user.orders.where(options).sum(&:total).roundf
  end

  def order_product_status(order)
    max_priority_status = order.order_products.sort{|a, b| b.status_priority<=>a.status_priority}.first.try(:status) || 0
    color_status(max_priority_status)
  end

  # link can be a string or a set of string
  def live_active?(link, active_class = "active")
    if link.is_a?(Array)
      link.inject(nil){|s, lin| s ||= live_active_helper?(lin, active_class)}
    elsif link.is_a?(String)
      live_active_helper?(link, active_class)
    end || ""
  end

  # use live_active? instead of
  def live_active_helper?(link, active_class)
    #regexp = link["manage"].present? ? /\/manage\/([\w\/]*)/ : /\/my\/([\w\/]*)/
    #current_uri = URI.unescape(link)
    #expect_uri = URI.unescape(request.url)
    #link_params = Rack::Utils.parse_nested_query(URI.parse(link).query)
    #expect_uri.scan(regexp) == current_uri.scan(regexp) && request.params.extract(link_params.keys).fixed_hash == link_params.fixed_hash ? active_class : nil

    act_contro_hash = ::Rails.application.routes.recognize_path(link).stringify_keys
    link_params = Rack::Utils.parse_nested_query(URI.parse(link).query).merge(act_contro_hash)
    link_params.in_hash(params) ? active_class : nil
  end

  def get_logistics(op_id)
    return nil if (tao_num = $redis.hget("PP::Opid::To::Tid", op_id)).blank?
    (s = $redis.hget("PP::Logistic", tao_num)).present? ? ActiveSupport::JSON.decode(s) : nil
  end
end
