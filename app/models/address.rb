class Address < ActiveRecord::Base
  belongs_to :user
  has_one :cart
  belongs_to :country
  delegate :englishname, :to => :country, :prefix => true, :allow_nil => true

  validates_presence_of :name, :country_id, :address1, :city, :province, :zip_code, :phone

  include Model::StateLib

  def state_dict
    return US_STATE if self.country_id == Country::USA || self.country_id.blank?
    CANADA_STATE if self.country_id == Country::CANADA
  end

  def province
    states = US_STATE.merge(CANADA_STATE)
    states[self['province']] || self['province']
  end

  def province_code
    self['province']
  end

  def manage_province
    US_STATE.merge(CANADA_STATE).key(self['province']) || self['province']
  end
end
