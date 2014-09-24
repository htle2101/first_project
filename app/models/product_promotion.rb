class ProductPromotion < ActiveRecord::Base
  include Util::ModelUtil

  REDIS_LAST_ERROR_TIME = "ump:last-error-time"
  REDIS_UMP_CACHE = "ump:cache"
  ERROR_INTERVAL = 10
  REIMPORT_INTERVAL = 5.days

  PROMOTION_TYPE = {
    "BC_VIRTUAL" => 1,
    "BC_REAL"    => 2
  }

  scope :tb_expired, where{tb_ended_at < Time.now}
  scope :bc_expired, where{bc_ended_at < Time.now}
  scope :bc_upcoming, where{(bc_started_at < Time.now) & (bc_started_at > 1.days.ago.to_date)}

  after_save :update_index
  after_destroy :update_index

  class << self
    def tfind(taobao_id)
      find_by_taobao_id(taobao_id)
    end

    def build_with_taobao(taobao_id, data)
      _data = data_extract(data)
      product = Product.tfind(taobao_id)
      promo = nil
      ProductPromotion.transaction do
        promo = self.create(_data.extract(:tb_price, :tb_started_at, :tb_ended_at).merge(:taobao_id => taobao_id))
        product.skus.each do |sku|
          sku.update_attribute(:promotion_price, _data[:skus][sku.sku_id])
        end
        product.update_index
      end
      promo.product = product
      promo
    end

    def data_extract(data)
      result = {
        :tb_price => data["item_promo_price"].try(:to_f),
        :tb_started_at => data["start_time"].try(:to_time),
        :tb_ended_at => data["end_time"].try(:to_time),
      }
      if data["sku_id_list"].present? && data["sku_price_list"].present?
        result[:skus] = {}
        data["sku_id_list"]["string"].each_with_index do |sku_id, index|
          result[:skus][sku_id.to_i] = data["sku_price_list"]["price"][index].to_f
        end
      end
      # some product maybe without sku, so do not check skus
      return if result[:tb_price].blank? || result[:tb_started_at].blank? || result[:tb_ended_at].blank?
      result
    end

    def update_error_time
      $redis.set(REDIS_LAST_ERROR_TIME, Time.now)
    end

    def sleep?
      time = $redis.get(REDIS_LAST_ERROR_TIME)
      return false if time.blank?
      (Time.now - time.to_time) > ERROR_INTERVAL
    end

    def add_to_cache(taobao_id)
      return if taobao_id.blank?
      $redis.hset(REDIS_UMP_CACHE, taobao_id, Time.now)
    end

    def reimport_check?(taobao_id)
      return if taobao_id.blank?
      time = $redis.hget(REDIS_UMP_CACHE, taobao_id)
      return if time.blank?
      (Time.now - time.to_time) > REIMPORT_INTERVAL
    end

  end

  def product
    @product ||= tfind(taobao_id)
  end

  def product=(product)
    @product = product
  end

  def on_taobao_promotion?
    @on_taobao_promotion ||= begin
      return false if tb_price.blank? || tb_started_at.blank? || tb_ended_at.blank?
      Time.now.between?(tb_started_at, tb_ended_at)
    end
  end

  def on_buychina_promotion?
    @on_buychina_promotion ||= begin
      return false if bc_discount.blank?
      return false if bc_started_at.present? && Time.now < bc_started_at
      return true if bc_ended_at.blank?
      return Time.now < bc_ended_at if bc_started_at.blank? && bc_ended_at.present?
      Time.now.between?(bc_started_at, bc_ended_at)
    end
  end

  def on?
    on_buychina_promotion? || on_taobao_promotion?
  end

  def bc_discount_rate
    1 - bc_discount / 100.0
  end

  def bc_virtual_discount_rate
    1 + bc_discount / 100.0
  end

  def bc_promotion_real?
    promotion_type == PROMOTION_TYPE["BC_REAL"]
  end

  def bc_promotion_virtual?
    promotion_type == PROMOTION_TYPE["BC_VIRTUAL"]
  end
  
  def buychina_clear
    update_attributes(:bc_discount => nil, :bc_started_at => nil, :bc_ended_at => nil, :promotion_type => nil)
  end

  def taobao_clear
    ProductPromotion.transaction do
      update_attributes(:tb_price => nil, :tb_started_at => nil, :tb_ended_at => nil)
      product.skus.update_all(:promotion_price => nil)
    end
    self
  end

  def taobao_update(data)
    _data = self.class.data_extract(data)
    ProductPromotion.transaction do
      update_attributes(_data.extract(:tb_price, :tb_started_at, :tb_ended_at))
      product.skus.each do |sku|
        sku.update_attribute(:promotion_price, _data[:skus][sku.sku_id])
      end
    end
    self
  end

  def update_index
    product.update_index if product.present?
  end

end
