# coding: utf-8
class ItemProp < ActiveRecord::Base
  has_many :categories_item_props, :primary_key => "pid", :foreign_key => "pid"
  has_many :categories, :through => :categories_item_props
  has_many :prop_values, :foreign_key => "pid", :primary_key => 'pid'
  translates :name, :slug, :fallbacks_for_empty_translations => true
  extend Translator::Base
  include Translator::Import
  extend FriendlyId
  friendly_id :name, :use => [:globalize, :slugged]#, :scope => :pid

  default_scope where{(status == nil) | (status != "deleted")}
  scope :simple, select('id, pid, name')
  scope :active, where{ status != "inactive" }

  STATUS = {"normal" => "显示", "inactive" => "隐藏", "deleted" => "删除"}
  class << self
    def logger
      Category.logger
    end

    def import_props
      Category.where(:is_parent => false, :is_prop => false).find_each do |c|
        import(c) ? c.update_attribute(:is_prop, true) : next
      end
    end

    def import(c)
      fields = "pid,name,must,multi,prop_values,parent_pid,parent_vid,is_key_prop,is_color_prop,is_sale_prop,is_enum_prop,is_item_prop,sort_order,status,is_input_prop,is_allow_alias"
      options = {:cid => c.cid, :fields => fields}
      proc do
        results = Taobao::Client.new.invoke("taobao.itemprops.get", options)["itemprops_get_response"] || {}
        props = results["item_props"].try(:fetch, "item_prop")
        !props.blank? and props.each{|p| create_prop(p, c) }
      end.call rescue false
    end

    def get_attributes(arg)
      arg.keys.inject({:locale => :cn}){|h, k| (h.merge!(k.to_sym => arg[k]) unless k == 'prop_values') || h}
    end

    def create_prop(p, c)
      prop = self.find_by_pid(p['pid'])
      unless prop
        prop = self.create(get_attributes(p))
        translate_elements(['en', 'ru'], self.where{{pid => p['pid']}})
        logger.info "#{prop.pid}: #{prop.name(:cn)}"
      end
      prop.update_column(:name, prop.name(:cn)) unless prop.original_name.present?
      unless CategoriesItemProp.find_by_cid_and_pid(c.cid, p['pid'])
        c.item_props << prop
      end
      create_value(p, c)
    end

    def create_value(p, c)
      prop_values = p['prop_values'].try(:fetch, 'prop_value')
      prop_values and prop_values.each do |v|
        value = PropValue.find_by_pid_and_vid(p['pid'], v['vid'])
        unless value
          value = PropValue.create(get_attributes(v).merge!(:pid => p['pid']))
          translate_elements(['en', 'ru'], PropValue.where{{pid => p['pid'], vid => v['vid']}})
          logger.info "#{value.pid}-#{value.vid}: #{value.name(:cn)}"
        end
        Brand.find_or_create_by_pid_and_vid(value.pid, value.vid) if value.pid == 20000
        value.update_column(:name, value.name(:cn)) unless value.original_name.present?
        unless CategoriesPropValue.find_by_cid_and_vid(c.cid, v['vid'])
          c.prop_values << value
        end
      end
    end
  end

  def update_slug
    [:en, :cn, :ru].each{|lang| I18n.with_locale(lang){ self.save }}
    self.update_column(:name, self.name(:cn)) if self.name(:cn).present?
  end
end
