class Photo < ActiveRecord::Base
  has_and_belongs_to_many :purchase_products
  mount_uploader :image, ImageUploader, :copy => false
end
