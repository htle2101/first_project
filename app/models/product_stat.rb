class ProductStat < ActiveRecord::Base
  belongs_to :product, :foreign_key => :taobao_id 
  include Model::ProductStatLib
end
