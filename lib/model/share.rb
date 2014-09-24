module Model
  module Share
    module ProductAndSku

      PRICE_RANGE = {
        (1..3) => 0.2,
        (4..7) => 0.19,
        (8..15) => 0.18,
        (16..20) => 0.17,
        (21..99) => 0.16,
        (100..Float::INFINITY) => 0.15
      }

      def bc_price(quantity = 1, old_price = nil)
        old_price = old_price || self.discount_price
        addition = old_price > 5 ? find_range(quantity) : 0.2
        old_price = old_price * (1 + addition)
        (old_price + 10.0 / quantity) / APP_CONFIG[:exchange_rate]
      end

      def find_range(quantity)
        PRICE_RANGE.each do |key, val|
          return val if key.include?(quantity)
        end
      end

      def valid_quantity(quantity)
        return 1 if quantity <= 0
        quantity
      end

      def taobao_price(bc_p)
        return 0 if bc_price(1, 0) >= bc_p
        price = bc_p * APP_CONFIG[:exchange_rate] - 10.0
        addition = find_range(1)
        (price / (1 + addition)).roundf(2)
      end

      def discount_price
        return self.price unless on_promotion?
        if promotion.on_buychina_promotion?
          promotion.bc_promotion_real? ?  self.price * promotion.bc_discount_rate : self.price
        else
          self.tb_promotion_price
        end
      end

      def original_price(quantity = 1)
        if promotion.present? && promotion.on_buychina_promotion? && promotion.bc_promotion_virtual?
          return bc_price(quantity, self.price * promotion.bc_virtual_discount_rate)
        end
        bc_price(quantity, self.price)
      end

      def discount
        return 0 unless on_promotion?
        if promotion.on_buychina_promotion?
          promotion.bc_discount.round
        else
          ((1 - promotion.tb_price / self.price.to_f) * 100).round
        end
      end

    end

    module LineItemAndOrderProduct
      include ActionView::Helpers::TagHelper

      def pv_values_html(locale = I18n.locale)
        pv_values(locale).split(";").inject("") do |html, content|
          html << content_tag(:span, content)
        end if pv_values(locale).present?
      end

      def total_weight(ship_method = nil)
        if ship_method
          (self.respond_to?(:product) ? self.product : self).volume_weight(ship_method)
        else
          self.weight.to_f * self.quantity
        end
      end

      def total_price
        (self.price * self.quantity).round(2)
      end
    end

  end
end
