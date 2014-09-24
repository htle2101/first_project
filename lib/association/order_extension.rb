module Association
  module OrderExtension
    def amount
      sum(&:total)
    end

    def amount_with_round
      sum(&:total).round(2)
    end

    def numbers
      map(&:number).join(",")
    end
  end
end
