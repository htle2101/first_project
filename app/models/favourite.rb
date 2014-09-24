class Favourite < ActiveRecord::Base
  belongs_to :user
  belongs_to :resource, :polymorphic => true

  include Util::ModelUtil

  def target
    resource_type == "Product" ? product_model(resource_id).find_by_taobao_id(resource_id) : self.resource
  end
end
