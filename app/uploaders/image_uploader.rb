# encoding: utf-8
class ImageUploader < CarrierWave::Uploader::Base
  include CarrierWave::MiniMagick
  storage :file

  def store_dir
    if model
      dir_name = model.class.name.instance_eval{ self == "FrontCategory" ? tableize : underscore }
      "system/uploads/#{dir_name}/#{mounted_as}/#{model.id}"
    else
      "system/uploads/front_modules"
    end
  end

  process :resize_original

  def resize_original
    resize_to_fit(300, 300) if model.class.to_s == 'Guide'
  end

  version :small, :if => :need_small? do
    process :resize_to_fit => [80, 80]
  end

  def need_small? image
    ['TopicProduct', 'Photo'].include?(model.class.to_s)
  end

  def extension_white_list
    %w(jpg jpeg gif png)
  end

  def filename
    if @filename
      "#{Time.now.to_i.to_s}-#{@filename}"
    end
  end
end
