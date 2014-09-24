class UploadImageUploader < ImageUploader
  def filename
    if model && (file_name = model.read_attribute(:name)).present?
      "#{file_name}.#{file.extension}"
    else
      super
    end
  end
end
