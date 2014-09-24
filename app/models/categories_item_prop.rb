class CategoriesItemProp < ActiveRecord::Base
  belongs_to :category, :primary_key => "cid", :class_name => "Category", :foreign_key => "cid"
  belongs_to :item_prop, :primary_key => "pid", :class_name => "ItemProp", :foreign_key => "pid"
end
