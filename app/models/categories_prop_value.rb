class CategoriesPropValue < ActiveRecord::Base
  belongs_to :category, :primary_key => "cid", :class_name => "Category", :foreign_key => "cid"
  belongs_to :prop_value, :primary_key => "vid", :class_name => "PropValue", :foreign_key => "vid"
end
