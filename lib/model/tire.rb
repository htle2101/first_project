module Model
  module Tire

    def to_hash
     serializable_hash(:except => :weight)
    end

  end
end
