module Association
  module LineItemExtension
    def sub_total
      sum(&:total_price)
    end

    def weight
      sum(&:total_weight) / 1000
    end

    def length
      sum(&:length)
    end

  end
end
