# coding: utf-8
module Model
  module ProductLib
    extend ActiveSupport::Concern

    STATUS = {
      "NORMAL" => 1,
      "DOWN" => 2
    }
    
    def update_sku
      if updated_at < Time.now - 2.days
        self.downshelf and return if (new_item = Item.get_taobao_item(self.taobao_id)).blank?
        [skus, prop_aliases].map(&:destroy_all)
        product, obj = self, Util::Importer2.new(Item.new(new_item))
        obj.instance_eval do
          if @tao_p.approve_status == "onsale"
            product.update_attribute(:delisted_at, @tao_p.delist_time)
            @product = product
            execute(build_sku)
            last_insert_id = insert(build_prop_alias)
            execute(build_prop_alias_translate(last_insert_id))
            @product.translate_props_with_data(prop_aliases, last_insert_id, true) rescue nil if need_translate?
          else
            product.downshelf
          end
        end
        self.updated_at = Time.now and save
        self.expire_cache
      end
    end

    def cache_url
      slug[0..130]
    end

    def on_sale?
      self.status == STATUS["NORMAL"] && self.category_active?
    end

    def enc_id
      @enc_id || Util::Crypto.encrypt("#{taobao_id}")
    end

    def url(short = false)
      "/items/#{short ? enc_id : slug}"
    end

    def store
      self.store_id ? Store.find_by_id(self.store_id) : Store.new(:name => self.store_name)
    end

    def has_sku?
      skus.count > 0
    end

    def share_link(current_user, base_url, params)
      base_url += self.url(true)
      if current_user.present?
        base_url += "?" + params.merge({:r => current_user.affiliate_id.to_s}).mdelete("action", "controller", "id", "ragent").to_param
      end
      base_url
    end

    def commission_price
      bc_price * APP_CONFIG[:commission_base_rate]
    end

    def specs
      spec_ids = self.props.split(";").group_by(&props_group)
      item_props = ItemProp.includes(:translations).active.simple.where{pid.in spec_ids.keys}.group_by(&:pid)
      prop_values = PropValue.includes(:translations).simple.where{vid.in spec_ids.values}.group_by(&:pid)
      specs = {}
      prop_values.each_pair do |key, values|
        if item_props[key].present?
          pvs = values.inject([]) do |props, pv|
            props << {:name => pv.name, :url => pv.display? ? pv.display_url : nil}
          end
          specs[item_props[key].first.name] = pvs
        end
      end
      (spec_ids.keys - item_props.keys).each do |pid|
        $redis.sadd("get_failed_props:set", "#{self.cid}:#{pid}")
      end
      specs
    end

    def selections(sku = nil)
      prop_ids = (sku.present? ? sku.prop_pair : self.skus.can_sale.map(&:prop_pair)).flatten.group_by(&props_group)
      item_props = ItemProp.includes(:translations).simple.where{pid.in prop_ids.keys}.group_by(&:pid)
      prop_values = PropValue.includes(:translations).simple.where{(vid.in prop_ids.values) & (pid.in prop_ids.keys)}.group_by(&:pid)
      pas = self.prop_aliases.group_by(&:pid)
      selections = {}
      prop_values.each_pair do |key, values|
        if item_props[key].present?
          selections[item_props[key].first] = merge_alias(values, pas[key])
          prop_ids.delete(key.to_s)
        end
      end
      prop_ids.each_pair do |key, values|
        if pas[key].present? && item_props[key].present?
          selections[item_props[key].first] ||= []
          selections[item_props[key].first] += pas[key].select {|pa| values.include?(pa.vid.to_s)}.map(&:override_prop_value)
        end
      end
      selections
    end

    def name_and_prop_aliases(need_pre_translation = false, need_prop_alias_ids = false)
      _name = need_pre_translation ? pre_translation : self.name(:cn)
      prop_alias_ids, data = [], [_name]
      self.prop_aliases.each do |pa|
        prop_alias_ids << pa.id
        data << pa.alias_name(:cn)
      end
      need_prop_alias_ids ? {:prop_alias_ids => prop_alias_ids, :data => data} : data
    end

    def translate_props(need_pre_translation = false)
      results = Translator::Base.translate(name_and_prop_aliases(need_pre_translation), :to => ['en', 'ru'])
      update_translations(results)
    end

    def update_translations(results)
      results.each_with_index do |result, index|
        element = index == 0 ? self : self.prop_aliases[index-1]
        hash = {:en => result[0], :ru => result[1]}
        element.class.update_element(element, hash, element.class.translated_attribute_names[0])
      end
    end

    def translate_props_with_data(prop_aliases, last_insert_id, need_pre_translation = false)
      data = (prop_aliases || []).map {|pa| pa[:alias_name]}
      _name = need_pre_translation ? pre_translation : self.name(:cn)
      data.insert(0, _name)
      results = Translator::Base.translate(data, :to => ['en', 'ru'])
      update_translations_by_sql(results, last_insert_id)
    end

    def update_translations_by_sql(results, last_insert_id)
      suffix = self.class.suffix(true)
      product, prop_aliases = results.shift, results
      sql = Translator::SQL.build_sql("product_translations#{suffix}", 'product_id', 'name', [{:pk => self.id, :content => product}])
      ActiveRecord::Base.connection.execute(sql)
      return if prop_aliases.length <= 0
      datas = []
      prop_aliases.each_with_index do |pa, index|
        datas << {:pk => last_insert_id + index, :content => pa}
      end
      sql = Translator::SQL.build_sql("prop_alias_translations#{suffix}", 'prop_alias_id', 'alias_name', datas)
      ActiveRecord::Base.connection.execute(sql)
    end

    def weight
      @weight ||= begin
                    return self['weight'] if self['weight'].to_i != 0
                    category && category.self_and_ancestors.map(&:weight).reverse.detect{|w| w && w != 0}
                  end
    end

    def ship_weight(ship_method)
      vw = volume_weight(ship_method)
      vw && vw > weight ? vw : weight
    end

    def volume_weight(ship_method)
      base = ship_method == 0 ? 8000 : 5000
      volume / base
    end

    def volume
      length.to_f * height.to_f * width.to_f
    end

    def valid_name(name = nil)
      return if (_name = (name || self.name)).blank?
      _name.gsub(/[^\w ]/, " ").squish
    end

    def name_and_taobao_id
      ("#{name(:en) || name} #{enc_id}").valid_name
    end

    def pre_save_slug
      normalize_friendly_id(name_and_taobao_id)
    end

    def shipping_methods(country = nil, price = nil, quantity = 1)
      @asms ||= if self.weight.present?
                  compare = {:volume => self.volume * quantity, :weight => self.weight * quantity / 1000}
                  options = {:country => country, :price => (price || self.bc_price) * quantity, 
                             :compare => compare, :length => length, :width => width, :height => height}
                  ExpressCal::Cost.shipping_methods(options)
                else
                  []
                end
    end

    def pre_translation
      keywords = redis.hgetall('translated:keywords') || {}
      _original_name = self.name(:cn).clone
      keywords.each_pair { |en, cn| _original_name.gsub!(cn, " #{en} ") }
      _original_name
    end

    def update_prop_alias_name
      ids = self.prop_aliases.map(&:id)
      unless ids.blank?
        suffix = self.class.suffix(true)
        sql = <<-SQL
          update prop_aliases#{suffix} pa, prop_alias_translations#{suffix} pat
          set pa.alias_name = pat.alias_name
          where pat.prop_alias_id in (#{ids.join(",")}) and pat.locale = 'cn'
          and pa.id = pat.prop_alias_id
        SQL
        ActiveRecord::Base.connection.execute(sql)
      end
    end

    def update_slug
      I18n.with_locale(:en) do
        _name = self.translations.find_by_locale('en').try(:reload).try(:name)
        self.name = self.valid_name(_name) if _name
        self.save
      end
    end

    def on_promotion?
      promotion.present? && promotion.on?
    end

    def tb_promotion_price
      on_promotion? ? promotion.tb_price : self.price
    end

    def expire_cache
      self.update_attributes(:updated_at => Time.now) and self
      #Util::Common::URL_PREFIX.map do |key, value|
        #delete_cache("#{value}/products/#{self.taobao_id}", :own_dir => "products")
      #end and self
    end

    def category_active?
      active = self.category.try(:active?)
      active.nil? ? true : active
    end

    def upshelf
      update_attributes(:status => STATUS["NORMAL"])
      expire_cache
    end

    def downshelf
      update_attributes(:status => STATUS["DOWN"])
      expire_cache
    end

    def avg_star
      pfs = self.product_feedbacks
      pfs.map(&:stars).sum / pfs.size
    end

    def update_partial_index(doc)
      tire.update_partial_index(doc, {:parent => self.cid})
    end

    def update_data(attributes, options = {})
      result = self.class.unscoped.where(self.class.primary_key => id).update_all(attributes)
      self.update_partial_index(attributes) if options[:update_index] == true
      result
    end

    private
    def merge_alias(prop_values, pas)
      return prop_values if pas.blank?
      results = prop_values.map do |pv|
        prop_alias = pas.detect {|pa| pa.pvid == pv.prop}
        if prop_alias.present?
          prop_alias.override_prop_value(pv)
          pas.reject! {|pa| pa == prop_alias}
        end
        pv
      end
      results
    end

    def props_group
      proc do |prop|
        key = prop[/\d+/]
        prop.sub!(/\d+:/,'')
        key.to_i
      end
    end

    def name_en
      self.name(:en)
    end

    def redis
      @redis ||= Redis.new
    end

    def self.included(base)
      base.class_eval do
        settings({ :store => { :compress => { :stored => true, :tv => true } } }) do
          mapping "_parent" => {"type" => "category"}, "_source" => {'compress' => true} do
            indexes :id, :type => 'integer', :index => :not_analyzed
            indexes :name_en, :type => 'string', :as => "name(:en)"
            indexes :name_ru, :type => 'string', :as => "name(:ru)"
            indexes :name_cn, :type => 'string', :as => "name(:cn)"
            indexes :cid, :type => 'long', :index => :not_analyzed
            indexes :store_id, :type => 'integer', :index => :not_analyzed
            indexes :taobao_id, :type => 'long', :index => :not_analyzed
            indexes :price, :type => 'float', :index => :not_analyzed
            indexes :bc_price, :type => 'float', :as => :bc_price, :index => :not_analyzed
            indexes :original_price, :type => 'float', :as => :original_price, :index => :not_analyzed
            indexes :discount, :type => 'integer', :as => :discount, :index => :not_analyzed
            indexes :on_promotion, :type => 'boolean', :as => :on_promotion?, :index => :not_analyzed
            indexes :pic_url, :type => 'string', :index => :not_analyzed
            indexes :store_name, :type => 'string', :index => :not_analyzed
            indexes :weight, :type => 'float', :index => :not_analyzed
            indexes :url, :type => 'string', :as => :url, :index => :not_analyzed
            indexes :store_score, :type => 'integer', :as => "store.try(:score)", :index => :not_analyzed
            indexes :store_level, :type => 'integer', :as => "store.try(:level)", :index => :not_analyzed
            indexes :item_props, :type => 'long',
              :as => "props.to_s.split(';').map {|e| e.split(':').first}.uniq.map(&:to_i)", :index => :not_analyzed
            indexes :pvs, :type => 'string', :as => "props.to_s.split(';')", :index => :not_analyzed
            indexes :lft, :type => 'integer', :as => 'category.try(:lft)', :index => :not_analyzed
            indexes :rgt, :type => 'integer', :as => 'category.try(:rgt)', :index => :not_analyzed
            indexes :status, :type => 'integer', :index => :not_analyzed
            indexes :created_at, :type => 'date', :index => :not_analyzed
            indexes :updated_at, :type => 'date', :index => :not_analyzed
          end
        end

        def to_hash
          serializable_hash.merge(:_parent => self.cid)
        end

      end
    end

    module ClassMethods
      def suffix(with_underline = false)
        suffix = self.name[/\d+$/] || ""
        return suffix unless with_underline
        suffix.blank? ? "" : "_#{suffix}"
      end
    end #end ClassMethods

    def self.generate(binding)
      Rails.configuration.pgr.each do |i|
        klass = <<-EOF
        class Product#{i} < ActiveRecord::Base
          self.table_name = "products_#{i}"
          has_one :stat, :class_name => "ProductStat#{i}", :primary_key => "taobao_id", :foreign_key => "taobao_id"
          has_one :detail, :class_name => "ProductDetail#{i}", :foreign_key => "product_id", :dependent => :destroy
          has_many :images, :class_name => "ProductImage#{i}", :foreign_key => "product_id", :dependent => :destroy
          has_many :skus, :class_name => "ProductSku#{i}", :foreign_key => "product_id", :dependent => :destroy
          has_many :prop_aliases, :class_name => "PropAlias#{i}", :foreign_key => "product_id", :dependent => :destroy
          belongs_to :store
          belongs_to :category, :foreign_key => :cid, :primary_key => :cid
          has_many :favourites, :as => :resource
          has_many :users, :through => :favourites
          has_many :product_feedbacks, :foreign_key => :taobao_id, :primary_key => :taobao_id
          has_one :promotion, :class_name => "ProductPromotion", :foreign_key => :taobao_id, :primary_key => :taobao_id
          delegate :shop_link, :to => :store, :prefix => true, :allow_nil => true

          include Tire::Model::Search
          include Tire::Model::Callbacks

          include ::Model::ProductLib
          include Util::ImageVersion
          include ::Model::Share::ProductAndSku
          extend Util::ModelUtil
          include Util::Cache

          accepts_nested_attributes_for :detail, :allow_destroy => true
          accepts_nested_attributes_for :skus, :allow_destroy => true

          translates :name, :fallbacks_for_empty_translations => true, :table_name => 'product_translations_#{i}', :foreign_key => 'product_id'

          extend FriendlyId
          friendly_id :name_and_taobao_id, :use => :slugged
          include Translator::Import
          image_attr :pic_url
          document_type 'product'
        end
        EOF
        eval(klass, binding)
      end
    end
  end
end
