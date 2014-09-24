module Model
  module ProductDetailLib
    extend ActiveSupport::Concern

    def clear_description
      self.update_attribute('description', tidy_desc) unless self.description.blank?
    end

    def tidy_desc
      return description if description.blank?
      doc = Nokogiri::HTML.parse(description)
      (doc/'img[@src^="http://img"]').inject(arr = []) do |arr, img|
        im = img.to_html
        arr << im if (img.attributes.size == 1) || im.match(/ width="?'?7/) || (!im.match(/ border=?/) && im.match(/ align=?/))
        arr
      end.join
    end

    def item_link_desc
      return description if description.blank?
      doc = Nokogiri::HTML.parse(description)
      (doc/'a[@href^="http://item.taobao.com"]').each do |link|
        taobao_id = link.attributes["href"].value[/(?<=id=)\d+/]
        link.attributes["href"].value = "http://www.buychina.com/products/#{taobao_id}" if taobao_id.present?
      end
      doc.to_html
    end

    def edited
      self.product.update_attributes(:detail_edited => 1) if self.description_changed?
    end

    module ClassMethods
      def clear_details
        self.find_each do |d|
          d.clear_description
        end
      end
    end

    def self.generate(binding)
      Rails.configuration.pgr.each do |i|
        klass = <<-EOF
        class ProductDetail#{i} < ActiveRecord::Base
          self.table_name = "product_details_#{i}"
          belongs_to :product, :class_name => "Product#{i}", :foreign_key => "product_id"

          include Model::ProductDetailLib

          after_update :edited
        end
        EOF
        eval(klass, binding)
      end
    end
  end
end
