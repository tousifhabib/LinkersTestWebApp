require 'rails_helper'

RSpec.describe AddressIndexBuilder do
  let(:builder) { AddressIndexBuilder.new }
  let(:sample_addresses) do
    [
      AddressData.new("100-0001", "東京都", "千代田区", nil, nil, nil, nil, nil),
      AddressData.new("600-8216", "京都府", "京都市下京区", "東塩小路町", "京都タワー", nil, nil, nil)
    ]
  end

  before do
    allow(builder).to receive(:load_csv).and_return(sample_addresses)
  end

  describe '#build' do
    it 'creates inverted index and addresses files' do
      index_file = StringIO.new
      addresses_file = StringIO.new

      allow(File).to receive(:open).with(Rails.root.join('tmp', 'inverted_index.msgpack'), 'wb').and_yield(index_file)
      allow(File).to receive(:open).with(Rails.root.join('tmp', 'addresses.msgpack'), 'wb').and_yield(addresses_file)

      builder.build

      expect(index_file.size).to be > 0
      expect(addresses_file.size).to be > 0
    end

    it 'builds the correct inverted index' do
      index_file = StringIO.new
      addresses_file = StringIO.new

      allow(File).to receive(:open).with(Rails.root.join('tmp', 'inverted_index.msgpack'), 'wb').and_yield(index_file)
      allow(File).to receive(:open).with(Rails.root.join('tmp', 'addresses.msgpack'), 'wb').and_yield(addresses_file)

      builder.build

      index_file.rewind
      unpacked_index = MessagePack.unpack(index_file.string)
      # Convert arrays back to sets for comparison
      unpacked_index.transform_values! { |v| Set.new(v) }

      expected_index = builder.build_inverted_index(sample_addresses)
      expect(unpacked_index).to eq(expected_index)
    end

    it 'handles invalid CSV data gracefully' do
      allow(builder).to receive(:load_csv).and_raise(StandardError.new('CSV parse error'))
      expect { builder.build }.to raise_error(StandardError, 'CSV parse error')
    end
  end
end
