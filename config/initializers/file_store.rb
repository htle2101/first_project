module ActiveSupport
  module Cache
    class FileStore < Store
      protected
      def read_entry(key, options)
        file_name = key_file_path(key, options)
        if File.exist?(file_name)
          File.open(file_name) { |f| Marshal.load(f) }
        end
      rescue
        nil
      end

      def write_entry(key, entry, options)
        file_name = key_file_path(key, options)
        ensure_cache_path(File.dirname(file_name))
        File.atomic_write(file_name, cache_path) {|f| Marshal.dump(entry, f)}
        true
      end

      def delete_entry(key, options)
        file_name = key_file_path(key, options)
        if File.exist?(file_name)
          begin
            File.delete(file_name)
            delete_empty_directories(File.dirname(file_name))
            true
          rescue => e
            # Just in case the error was caused by another process deleting the file first.
            raise e if File.exist?(file_name)
            false
          end
        end
      end

      private
      def key_file_path(key, options = nil)
        own_dir = options[:own_dir] if options
        fname = Rack::Utils.escape(key)
        hash = Zlib.adler32(fname)
        hash, dir_1 = hash.divmod(0x1000)
        dir_2 = hash.modulo(0x1000)
        fname_paths = []

        # Make sure file name doesn't exceed file system limits.
        begin
          fname_paths << fname[0, FILENAME_MAX_SIZE]
          fname = fname[FILENAME_MAX_SIZE..-1]
        end until fname.blank?

        if own_dir.present?
          File.join(cache_path, own_dir, DIR_FORMATTER % dir_1, DIR_FORMATTER % dir_2, *fname_paths)
        else
          File.join(cache_path, DIR_FORMATTER % dir_1, DIR_FORMATTER % dir_2, *fname_paths)
        end
      end
    end
  end
end

