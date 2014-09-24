class Message < ActiveRecord::Base
  CATEGORY = {1 => "shipping", 2 => "payment", 3 => "complain", 4 => "other"}
  validates :subject, :presence => true
  has_many :replies, :dependent => :destroy
  accepts_nested_attributes_for :replies, :allow_destroy => true
  belongs_to :user

  scope :admin_convs_for, lambda {|category, is_unread| send(category).where(:admin_unread => is_unread).order('updated_at DESC') }
  store :related_spec, {:accessors => :quantity}
  default_values :category => 0, :admin_unread => true, :user_unread => false

  class << self
    def order_unread?(order)
      orders.find_by_related_id(order.number).try :user_unread?
    end

    def get_related_conversation(item_id, item_category = "orders")
      send(item_category).find_by_related_id(item_id)
    end

    def admin_unread_count
      self.where(:admin_unread => true).group('related_type').count
    end
  end

  def mark_as_read(type)
    update_attributes("#{type}_unread" => false)
  end

  def mark_as_unread(type)
    update_attributes("#{type}_unread" => true)
  end

  def spec
    ActiveSupport::JSON.decode related_spec
  end

  def related_item
    case related_type
    when "Product" then Product.tfind(related_id)
    when "Order" then Order.find_by_number(related_id)
    end
  end

  def newest_message
    bc_messages.last
  end

  def get_category
    CATEGORY[self.related_id]
  end
end
