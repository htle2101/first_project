class ProductFeedback < ActiveRecord::Base
  belongs_to :user
  belongs_to :order
  belongs_to :order_product

  REVIEW_TYPE = {'by_user' => 1, 'by_system' => 2}

  default_value_for :review_type, 1
  before_create :set_attributes

  def get_review_type
    REVIEW_TYPE.key(review_type || 2)
  end

  def product
    Product.tfind(self.taobao_id) || Product.new(:taobao_id => self.taobao_id)
  end

  private
  def set_attributes
    ['taobao_id', 'quantity', 'price'].each do |str|
      self[str] ||= order_product.send(str)
    end
    self.user_id ||= order.user_id
    self.user_name ||= order.user_name
    self.comment = self.comment.blank? ? I18n.t('views.my.product_feedbacks.show.holder_msg') : self.comment
  end
end
