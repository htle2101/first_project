class Country < ActiveRecord::Base
  default_scope order("priority DESC, englishname")
  scope :with_out_china, where("code != 'CN'")
  USA = 34
  CANADA = 35
  CHINA = 230

  CODE_ALIAS = { "C2" => "CN", "GB" => "UK" }

  class << self
    def usa
      where("code = 'US'").first
    end

    def dangerous_region?(country_id)
      country_id == 14 || country_id == 69 || country_id ==159
    end

    def country_code(code)
      CODE_ALIAS[code].present? ? CODE_ALIAS[code] : code
    end

    def find_id_by_code(code)
      Country.select('id').find_by_code(code)
    end

    def can_izone?(attribute)
      self.column_names.include?(attribute.to_s)
    end

    def max_izone(attribute)
      self.where("#{attribute} is not NULL").group(attribute.to_s).map(&attribute.to_sym).max
    end
  end

  def collect_by_id_and_name
    {:id => self.id, :name => self.name}
  end

  %w{singaporepostair swisspostair usps australianairexpress ukyodel chinaexpress airmail}.each do |m|
    define_method "#{m}" do
      nil
    end
  end

  def china?
    self.id == 230
  end
end
