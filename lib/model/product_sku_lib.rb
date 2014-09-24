module Model
  module ProductSkuLib
    extend ActiveSupport::Concern

    def prop_pair
      props.split(";")
    end

    def pv_values(locale = I18n.locale)
      @pv_values ||= begin
        selection = product.selections(self)
        content = ""
        selection.each_pair do |prop, values|
          content << "#{prop.name(locale)}: #{values.first.name(locale)};"
        end
        content
      end
    end

    def get_new_taobao_price
      self.price = self.taobao_price(self.price) unless self.to_taobao_price.blank?
    end

    def tb_promotion_price
      self.promotion_price || self.price
    end

    # instance methods end

    module ClassMethods
    end # ClassMethods end

    def self.generate(binding)
      Rails.configuration.pgr.each do |i|
        klass = <<-EOF
        class ProductSku#{i} < ActiveRecord::Base
          self.table_name = "product_skus_#{i}"
          belongs_to :product, :class_name => "Product#{i}", :foreign_key => "product_id"

          include Model::Share::ProductAndSku
          include Model::ProductSkuLib
          attr_accessor :to_taobao_price, :taobao_id
          before_update :get_new_taobao_price

          delegate :on_promotion?, :promotion, :to => :product, :allow_nil => true
          scope :can_sale, where("stock_num > 0")
        end
        EOF
        eval(klass, binding)
      end
    end
  end
end
