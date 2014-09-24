# coding: utf-8
class Category < ActiveRecord::Base
  has_many :categories_item_props, :primary_key => "cid", :foreign_key => "cid"
  has_many :item_props, :through => :categories_item_props, :class_name => 'ItemProp'
  has_many :categories_prop_values, :primary_key => "cid", :foreign_key => "cid"
  has_many :prop_values, :through => :categories_prop_values, :class_name => 'PropValue'
  has_and_belongs_to_many :front_categories, :class_name => "FrontCategory"
  has_many :taobaoke_products, :primary_key => "cid", :foreign_key => "cid"
  has_many :guides, :foreign_key => :leaf_id, :primary_key => 'cid'

  #validates :name, :presence => true
  validates :cid, :presence => true, :uniqueness => true
  translates :name, :fallbacks_for_empty_translations => true
  acts_as_nested_set
  attr_protected :lft, :rgt
  extend Translator::Base
  include Translator::Import
  STATUS = {"priority" => "优先", "normal" => "显示", "inactive" => "隐藏"}
  include Model::CategoryLib
  scope :active_roots, where(:status => 'normal', :parent_id => nil).order('alpha')

  extend FriendlyId
  friendly_id :name_en, :use => :slugged

  include Tire::Model::Search
  include Tire::Model::Callbacks

  include Util::Logger
  set_logger_file_name "update_category_and_props"

  mapping do
    indexes :id, :type => 'integer', :index => :not_analyzed
    indexes :cid, :type => 'long', :index => :not_analyzed
    indexes :parent_cid, :type => 'long', :index => :not_analyzed
    indexes :sort_order, :type => 'integer', :index => :not_analyzed
    indexes :lft, :type => 'integer', :index => :not_analyzed
    indexes :rgt, :type => 'integer', :index => :not_analyzed
    indexes :name_en, :type => 'string', :as => "name(:en)"
    indexes :name_ru, :type => 'string', :as => "name(:ru)"
    indexes :name_cn, :type => 'string', :as => "name(:cn)"
    indexes :slug, :type => 'string', :index => :not_analyzed
    indexes :status, :type => 'boolean', :as => :active?
    indexes :level, :type => 'integer', :as => :level
    indexes :has_brands, :type => "boolean", :as => "active_brands.present?"
    indexes :active_brands, :type => "long", :as => :active_brands
  end

  class << self
    def import(parent_cid = 0)
      options = {:parent_cid => parent_cid, :fields => "cid,parent_cid,name,is_parent,status,sort_order"}
      results = Taobao::Client.new.invoke("taobao.itemcats.get", options)["itemcats_get_response"] || {}
      taobao_categories = results["item_cats"].try(:fetch, "item_cat")
      !taobao_categories.blank? and taobao_categories.each do |tc|
        hash = tc.symbolize_keys
        category = Category.find_by_cid(tc['cid'])
        if category
          if category.status == "normal"
            reget_hash = hash.merge(:parent_id => Category.find_by_cid(parent_cid).try(:id), :is_traverse => false)
            category.update_attributes(reget_hash) if category.parent_cid != parent_cid || category.is_parent != hash[:is_parent]
          end
        else
          category = create(hash.merge(:parent_id => Category.find_by_cid(parent_cid).try(:id), :locale => :cn))
          translate_elements(['en', 'ru'], Category.where(:cid => tc["cid"]))
          logger.info "#{category.cid}/#{category.name(:cn)}"
        end
        category.update_column(:name, category.name(:cn)) unless category.original_name.present?
        ItemProp.import(category) && find_by_cid(tc['cid']).update_attribute(:is_prop, true) unless category.is_parent
        logger.info "#{category.id} / #{Category.last.id}"
        true
      end
    end

    def traverse(cid = 0)
      !Category.first || cid == 0 ? import : Category.find_by_cid(cid).self_and_descendants.update_all(:is_traverse => false)
      Category.update_all(:is_traverse => false) if cid == 0
      Category.where(:is_traverse => false, :is_parent => true).find_each do |c|
        import(c.cid) ? c.update_attribute(:is_traverse, true) : next
      end
      !Category.where(:is_traverse => false, :is_parent => true).blank? and traverse
    end

    def rebuild
      self.where("is_parent = 0").each do |category|
        Category.update_all("parent_id = #{category.id}", "parent_cid = #{category.cid}")
      end
    end

    def set_alpha
      I18n.locale = :en
      self.find_each do |c|
        c.alpha = c.name[0].downcase
        c.save(:valide => false)
      end
    end

    def search(cids)
      tire.search do 
        query do
          boolean do
            must {terms :cid, cids}
            must {term :status, true}
          end
        end
      end
    end

    def brand_categories
      tire.search(:size => 100) do 
        query do
          boolean do
            must { term :level, 0 }
            must { term :status, true }
            must { term :has_brands, true }
          end
        end
      end
    end
  end # end class << self

  def collect_by_id_and_name
    name = "#{self.level + 1} #{self.original_name} #{('< '+ self.root.name) unless self.root?}"
    {:id => self.id, :name => name}
  end

  def active_children
    Category.where(:status => 'normal', :parent_id => self.id).order('alpha')
  end

  def items
    @items ||= item_props.inject([]) do |result, e|
      result << {:pid => e.pid, :name_en => e.name(:en), :name_cn => e.name(:cn), :name_ru => e.name(:ru)}
    end
  end

  def props
    pids = items.inject([]) {|r,e| r << e[:pid]; r}
    props = []
    self.prop_values.where(:pid => pids).group_by(&:pid).each_pair do |k, v|
      values = v.map {|e| {:vid => e.vid, :name_en => e.name(:en), :name_cn => e.name(:cn), :name_ru => e.name(:ru)} }
      props << {:pid => k, :values => values }
    end
    props
  end

  def active?
    self.status != "inactive"
  end

  def size_pids
    item_props.find_all_by_name("Size").map(&:pid)
  end

  def name_en
    name(:en)
  end

  def product_index_data
    {:id => self.cid, :status => self.active?, "_type" => 'category'}
  end

  def update_index
    update_elasticsearch_index
    ::PRODUCTS.each do |klass|
      index = Tire.index(klass.index_name)
      index.store(product_index_data) if index.exists?
    end
  end

  def active_brands
    cid = self.cid
    @brands ||= Tire.search("brands") do
      query do 
        boolean do
          must { term :cids, cid }
          must { string "status:active" }
        end
      end
    end.results
    @brands.present? ? @brands : nil
  end
end
