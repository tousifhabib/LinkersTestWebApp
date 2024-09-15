Rails.application.config.after_initialize do
  AddressIndexManager.instance.load_or_build_index
end
