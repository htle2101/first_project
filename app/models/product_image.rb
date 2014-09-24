class ProductImage < ActiveRecord::Base
  belongs_to :product

  include Util::ImageVersion
  include Model::ProductImageLib

  image_attr :url

end
