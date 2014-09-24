class PropAlias < ActiveRecord::Base
  belongs_to :product
  translates :alias_name, :fallbacks_for_empty_translations => true
  extend Translator::Base
  include Translator::Import

  include Model::PropAliasLib

end
