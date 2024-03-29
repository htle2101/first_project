module Globalize
  module ActiveRecord
    module ActMacro
      def translates(*attr_names)
        return if translates?

        options = attr_names.extract_options!
        #options[:table_name] ||= "#{table_name.singularize}_translations"

        class_attribute :translated_attribute_names, :translation_options, :fallbacks_for_empty_translations
        self.translated_attribute_names = attr_names.map(&:to_sym)
        self.translation_options        = options
        self.fallbacks_for_empty_translations = options[:fallbacks_for_empty_translations]

        include InstanceMethods
        extend  ClassMethods, Migration

        translation_class.table_name = options[:table_name] if options[:table_name].present?  # if translation_class.table_name.blank?

        has_many :translations, :class_name  => translation_class.name,
                                :foreign_key => options[:foreign_key].present? ? options[:foreign_key] : class_name.foreign_key,
                                :dependent   => :destroy,
                                :extend      => HasManyExtensions

        after_create :save_translations!
        after_update :save_translations!

        if options[:versioning]
          ::ActiveRecord::Base.extend(Globalize::Versioning::PaperTrail)

          translation_class.has_paper_trail
          delegate :version, :versions, :to => :translation
        end

        attr_names.each { |attr_name| translated_attr_accessor(attr_name) }
      end
    end
  end
end
