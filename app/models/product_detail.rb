# coding: utf-8
class ProductDetail < ActiveRecord::Base
  belongs_to :product

  include Model::ProductDetailLib

  after_update :edited
end
