module Model
  module ProductImageLib
    extend ActiveSupport::Concern

    module ClassMethods

    end # end ClassMethods

    def self.generate(binding)
      Rails.configuration.pgr.each do |i|
        klass = <<-EOF
        class ProductImage#{i} < ActiveRecord::Base
          self.table_name = "product_images_#{i}"
          belongs_to :product, :class_name => "Product#{i}", :foreign_key => "product_id"

          include Util::ImageVersion
          include Model::ProductImageLib

          image_attr :url

        end
      EOF
      eval(klass, binding)
    end
  end
  end
end
