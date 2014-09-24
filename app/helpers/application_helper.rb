# coding: utf-8
module ApplicationHelper
  def fixed_controller
    return 'fixed' if ['posts', 'promotions', 'guides'].include?(controller_name) || ['affiliate', 'affiliate_faq'].include?(action_name)
    if FrontCategory::TYPE.values.include?(action_name)
      'fixed' if @front_category.template != 2
    end
  end

  def add_to_favorite(options = {})
    tp = FrontCategory.find_by_id(options['data-fcid'].to_i).try(:topic_products)
    active = tp && action_name == "add_products" ? tp.map(&:taobao_id).include?(options['data-id']) : false
    str = active ? 'button-favorite-active' : ''
    content = "<a href='javascript:;' class='favorite no #{options[:class]} #{str}'"
    content += " data-action=#{controller_name}-#{action_name} title='#{product_t 'add_favorite'}'"
    options.each{|key, value| content += " #{key} = '#{value}'" if key.to_s[/data/]}
    content += ">" + (options[:content] || "+#{product_t 'favorite'}") + " </a>"
    content.html_safe
  end

  def init_date(type = 'gteq', options = {}, month=1)
    value = options[:value] || (type == 'gteq' ? Time.now.months_ago(month).to_date : Time.now.tomorrow.to_date)
    column = options[:column] || 'created_at'
    (q = params[:q].try(:[], "#{column}_#{type}")) ? q : value
  end
end
