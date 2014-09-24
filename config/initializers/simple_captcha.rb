SimpleCaptcha.setup do |sc|
  # default: 100x28
  sc.image_size = '85x22'
  sc.length = 4
  # default: simply_blue
  # possible values:
  # 'embosed_silver',
  # 'simply_red',
  # 'simply_green',
  # 'simply_blue',
  # 'distorted_black',
  # 'all_black',
  # 'charcoal_grey',
  # 'almost_invisible'
  # 'random'
  #sc.image_style = 'simply_green'

  # default: low
  # possible values: 'low', 'medium', 'high', 'random'
  sc.distortion = 'medium'
end

module SimpleCaptcha
  module ViewHelper
    def show_simple_captcha(options={})
      key = simple_captcha_key(options[:object])
      options[:field_value] = set_simple_captcha_data(key, options)

      defaults = {
        :image => simple_captcha_image(key, options),
        :label => options[:label] || I18n.t('simple_captcha.label'),
        :field => simple_captcha_field(options)
      }
      render :partial => 'simple_captcha/simple_captcha', :locals => { :simple_captcha_options => defaults }
    end

    def simple_captcha_field(options={})
      html_options = options[:field_html_options] || {}
      html_options.merge!(:autocomplete => 'off')
      if options[:object]
        html_options.merge!(:value => '')
        text_field(options[:object], :captcha, html_options) +
          hidden_field(options[:object], :captcha_key, {:value => options[:field_value]})
      else
        text_field_tag(:captcha, nil, html_options)
      end
    end

    def simple_captcha_image(simple_captcha_key, options = {})
      defaults = {}
      defaults[:time] = options[:time] || Time.now.to_i

      query = defaults.collect{ |key, value| "#{key}=#{value}" }.join('&')
      url = "/simple_captcha/?code=#{simple_captcha_key}&#{query}"
      html_options = options[:img_html_options] || {:alt => 'captcha'}
      image_tag(url, html_options)
    end
  end
end
