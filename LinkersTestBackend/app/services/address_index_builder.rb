class AddressIndexBuilder
  include AddressSearchHelper

  def build
    addresses = load_csv(Rails.root.join('tmp', 'zenkoku.csv'))
    index = build_inverted_index(addresses)

    # Convert Sets to Arrays before saving
    index_to_save = index.transform_values(&:to_a)
    File.open(Rails.root.join('tmp', 'inverted_index.msgpack'), 'wb') do |file|
      file.write(MessagePack.pack(index_to_save))
    end

    File.open(Rails.root.join('tmp', 'addresses.msgpack'), 'wb') do |file|
      file.write(MessagePack.pack(addresses.map(&:to_a)))
    end
  end
end
