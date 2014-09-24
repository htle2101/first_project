module CarrierWave
  module Mount
    def mount_uploader_with_extension(column, uploader=nil, options={}, &block)
      copy = options[:copy] and options.delete(:copy)
      mount_uploader_without_extension(column, uploader, options, &block)
      if copy
        after_save :copy_image_path
        class_eval <<-RUBY, __FILE__, __LINE__+1
          def copy_image_path
            if self.send(:#{column}).path
              path = '/' + self.send(:#{column}).store_path
              image = ::MiniMagick::Image.new(self.send(:#{column}).path)
              size = image[:width].to_s + 'x' + image[:height].to_s
              name = self.send(:#{column}).filename
              ::Image.create(:name => name, :pic_url => path, :classify => self.class.name, :size => size)
            end
          end
        RUBY
      end
    end
    alias_method_chain :mount_uploader, :extension
  end
end
