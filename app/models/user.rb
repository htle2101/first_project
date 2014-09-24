require 'digest'
class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :omniauthable, :encryptable
  devise :database_authenticatable, :registerable,
    :recoverable, :rememberable, :trackable, :validatable,
    :token_authenticatable, :confirmable, :lockable, :timeoutable, :omniauthable

  attr_accessor :login

  # Setup accessible (or protected) attributes for your model
  attr_accessible :username, :email, :password, :password_confirmation, :remember_me,
    :first_name, :last_name, :gender, :location, :login, :provider, :uid, :current,
    :affiliate_id, :current_referral_code, :current_referral_at, :role_ids

  #validates_presence_of :password_confirmation, :if => :password_required?
  validates_presence_of :username, :email
  validates_uniqueness_of :username, :email
  validates_length_of :username, :minimum => 4, :maximum => 20
  validates_length_of :password, :minimum => 6, :maximum => 30, :allow_blank => true

  validates :username, :format => { :with => /^[a-z0-9_]+$/i, :message => "Only letters, numbers and underline allowed" }

  has_and_belongs_to_many :roles, :join_table => ::RolesUsers.table_name
  has_many :addresses
  has_many :order_adjustments, :conditions => 'price > 0'
  has_many :guides
  has_many :todo_tasks, :foreign_key => :current_user_id, :class_name => :Task, :conditions => {:status => Task::STATUS[:doing]}
  has_many :claimed_orders, :foreign_key => :claimant_id, :class_name => :Order, :conditions => {:status => [Order::ORDER_STATUS['PROCESSING'], Order::ORDER_STATUS['PENDING']]}
  has_one :cart
  has_many :orders, :extend => ::Association::OrderExtension
  %w{Store Product TaobaokeProduct}.each do |s|
    has_many "favourite_#{s.tableize}", :class_name => 'Favourite', :conditions => {:resource_type => s}
  end
  has_many :favourites
  has_many :stores, :through => :favourites, :source => :resource, :source_type => "Store"
  has_many :taobaoke_products, :through => :favourites, :source => :resource, :source_type => "TaobaokeProduct"
  has_one :account
  has_many :deposits
  has_many :referral_products, :foreign_key => :referral_user_id
  has_many :referrals, :foreign_key => :referral_user_id
  has_many :product_feedbacks
  has_many :messages#, :order => "updated_at DESC"
  delegate :unclaimed_orders, :to => Order

  include Model::Omniauth
  include Util::MessageAble
  include Util::Charts
  include Model::UserRole
  after_create :create_user_account

  scope :affiliate_users, where("affiliate_id is not null and affiliate_id != ''")

  class << self

    def current
      Thread.current[:user]
    end

    def current=(user)
      Thread.current[:user] = user
    end

    def support
      @@support ||= find_by_email('support@buychina.com')
    end

    def find_first_by_auth_conditions(warden_conditions)
      conditions = warden_conditions.dup
      if login = conditions.delete(:login)
        where(conditions).where(["lower(username) = :value OR lower(email) = :value", { :value => login.downcase }]).first
      else
        where(conditions).first
      end
    end

    def generate_affiliate_id
      begin
        affiliate_id = SecureRandom.hex(3)
      end while User.exists?(:affiliate_id => affiliate_id)
      affiliate_id
    end

    def managers
      User.joins(:roles).uniq
    end

  end # end class << self

  def can_delete?(user_to_delete = self)
    user_to_delete.persisted? and
    id != user_to_delete.id and
    !user_to_delete.has_role?(:superuser)
  end

  def dangerous_region?
    Country.dangerous_region?(self.country_id)
  end

  def order_count_by_status(*status)
    if (status = status.flatten).include?('partial_refunding')
      is_partial = true and status.delete('partial_refunding')
    end
    @order_count_by_status ||= orders.group('status').count
    return @order_count_by_status.values.sum if status[0].blank?
    r = status.inject(0) do |r, s|
      r += @order_count_by_status[Order::ORDER_STATUS[s]].to_i
    end
    @partial_count ||= orders.where('partial_status is not null').count if is_partial
    is_partial ? r + @partial_count.to_i : r
  end

  def match_address(country_id)
    return if self.addresses.blank?
    addr = self.addresses.detect {|addr| addr.country_id == country_id}
    addr
  end

  def current_referral_code
    Time.now > 15.days.since(current_referral_at) ? nil : self[:current_referral_code].split("-").first
  end

  def is_self_referral?(item)
    item.referral_user_id == self.id
  end

  # 参与过, 整个任务没有完成, 不是自己在处理的
  # 参与过, 整个任务已经完成, 三天以内的完成的
  def done_tasks(time = 3.days)
    Task.where("participate_ids like ?", "%- #{self.id}\n%")
        .where("(status = ? and completed_at >= ?) or (status = ? and current_user_id != ?)", 1, time.ago, 0, self.id)
  end

  def claim_order(order)
    order.update_attributes(:claimant_id => id) unless order.claimant_id?
  end


  private
  def create_user_account
    Account.find_or_create_by_user_id(self.id)
  end
end
