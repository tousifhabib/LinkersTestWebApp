require 'rails_helper'

RSpec.describe AddressSearchHelper, type: :helper do
  include AddressSearchHelper

  describe '#normalize' do
    it 'converts katakana to hiragana and normalizes text' do
      expect(normalize('トウキョウト')).to eq('とうきょうと')
      expect(normalize('キョウト')).to eq('きょうと')
    end
  end

  describe '#generate_2grams' do
    it 'generates correct 2-grams from text' do
      expect(generate_2grams('東京都')).to eq(%w[東京 京都])
      expect(generate_2grams('きょうと')).to eq(%w[きょ ょう うと])
      expect(generate_2grams('キョウト')).to eq(%w[きょ ょう うと])
    end
  end

  describe '#build_inverted_index' do
    let(:addresses) do
      [
        AddressData.new("100-0001", "東京都", "千代田区", nil, nil, nil, nil, nil),
        AddressData.new("600-8216", "京都府", "京都市下京区", "東塩小路町", "京都タワー", nil, nil, nil)
      ]
    end

    it 'builds an inverted index with correct 2-grams' do
      index = build_inverted_index(addresses)

      expect(index.keys).to include('東京', '京都', '都府', '千代', '代田', '田区', '市下', '下京', '京区', '東塩', '塩小', '小路', '路町', 'たわ', 'わー')
      expect(index['東京']).to include(0)
      expect(index['京都']).to include(0, 1)
    end
  end
end
