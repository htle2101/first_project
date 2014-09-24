# encoding: utf-8
class Order < ActiveRecord::Base
  has_many :order_products, :extend => ::Association::LineItemExtension

  class << self
    def generate_number
      number = Array.new(NUMBER_LENGTH){|i| i == 0 ? rand(9) + 1 : rand(10)}.join
      return number unless Order.exists?(:number => number)
      generate_number
    end
  end # end class << self

  def log_status(state = nil)
    I18n.with_locale(:cn) do
      I18n.t "models.order.status.#{ORDER_STATUS.key((state||self.status).to_i).downcase}"
    end
  end
end
