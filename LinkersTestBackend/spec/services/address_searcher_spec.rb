require 'rails_helper'

RSpec.describe AddressSearcher do
  include AddressSearchHelper

  let(:addresses) do
    [
      AddressData.new("100-0001", "東京都", "千代田区", nil, nil, nil, nil, nil),
      AddressData.new("150-0002", "東京都", "渋谷区", "渋谷", nil, nil, nil, nil),
      AddressData.new("150-0001", "東京都", "渋谷区", "神宮前", nil, nil, nil, nil),
      AddressData.new("530-0001", "大阪府", "大阪市北区", "梅田", nil, nil, nil, nil),
      AddressData.new("600-8216", "京都府", "京都市下京区", "東塩小路町", "京都タワー", nil, nil, nil),
      AddressData.new("160-0022", "東京都", "新宿区", nil, "京都通り", nil, nil, nil),
      AddressData.new("160-0023", "東京都", "新宿区", nil, "京都街", nil, nil, nil),
      AddressData.new("890-0053", "鹿児島県", "鹿児島市", "中央町", nil, nil, nil, nil),
      AddressData.new("260-0013", "千葉県", "千葉市中央区", "中央", nil, nil, nil, nil),
      AddressData.new("600-8001", "京都府", "京都市下京区", "真町", nil, nil, "京都都税事務所", nil)
    ]
  end

  let(:index) { build_inverted_index(addresses) }
  let(:address_index_manager) { instance_double(AddressIndexManager, addresses: addresses, index: index) }
  let(:searcher) { AddressSearcher.new(address_index_manager) }

  describe '#search' do
    it 'generates correct 2-grams' do
      expect(generate_2grams("東京都")).to eq(%w[東京 京都])
      expect(generate_2grams("きょうと")).to eq(%w[きょ ょう うと])
      expect(generate_2grams("キョウト")).to eq(%w[きょ ょう うと])
    end

    it 'searches single token "渋谷"' do
      expected_results = addresses.select { |a| a.full_address.include?("渋谷") }
      allow(address_index_manager).to receive(:search).with("渋谷").and_return(expected_results)
      results = searcher.search("渋谷")
      expect(results.length).to eq(2)
      expect(results.all? { |r| r.full_address.include?("渋谷") }).to be true
    end

    it 'searches multiple tokens "東京都渋谷"' do
      expected_results = addresses.select { |a| a.prefecture == "東京都" && a.full_address.include?("渋谷") }
      allow(address_index_manager).to receive(:search).with("東京都渋谷").and_return(expected_results)
      results = searcher.search("東京都渋谷")
      expect(results.length).to eq(2)
      expect(results.all? { |r| r.prefecture == "東京都" && r.full_address.include?("渋谷") }).to be true
    end

    it 'searches with no results' do
      allow(address_index_manager).to receive(:search).with("名古屋").and_return([])
      results = searcher.search("名古屋")
      expect(results).to be_empty
    end

    it 'searches for specific business name' do
      expected_result = addresses.select { |a| a.business_name == "京都都税事務所" }
      allow(address_index_manager).to receive(:search).with("京都都税事務所").and_return(expected_result)
      results = searcher.search("京都都税事務所")
      expect(results.length).to eq(1)
      expect(results.first.business_name).to eq("京都都税事務所")
    end

    it 'searches for Tokyo in different scripts' do
      expected_results = addresses.select { |a| a.prefecture == "東京都" }
      %w[トウキョウト とうきょうと 東京都].each do |query|
        allow(address_index_manager).to receive(:search).with(query).and_return(expected_results)
        results = searcher.search(query)
        expect(results.length).to be > 0
        expect(results.first.prefecture).to eq("東京都")
      end
    end

    it 'searches for Osaka in different scripts' do
      expected_result = addresses.select { |a| a.prefecture == "大阪府" }
      %w[オオサカフ おおさかふ 大阪府].each do |query|
        allow(address_index_manager).to receive(:search).with(query).and_return(expected_result)
        results = searcher.search(query)
        expect(results.length).to eq(1)
        expect(results.first.prefecture).to eq("大阪府")
      end
    end

    it 'searches Tokyo in other prefectures' do
      expected_results = addresses.select { |a| a.full_address.include?("東京") }
      allow(address_index_manager).to receive(:search).with("東京").and_return(expected_results)
      results = searcher.search("東京")
      tokyo_elsewhere = results.select { |r| r.prefecture != "東京都" && r.full_address.include?("東京") }
      expect(tokyo_elsewhere.length).to eq(0)
    end

    it 'searches for addresses containing "京都" in Tokyo' do
      expected_results = addresses.select { |a| a.prefecture == "東京都" && a.kyoto_street&.include?("京都") }
      allow(address_index_manager).to receive(:search).with("東京都京都").and_return(expected_results)
      results = searcher.search("東京都京都")
      expect(results.length).to eq(2)
      expect(results.all? { |r| r.prefecture == "東京都" && r.kyoto_street&.include?("京都") }).to be true
    end

    it 'searches Kyoto street in Tokyo' do
      expected_result = addresses.select { |a| a.prefecture == "東京都" && a.kyoto_street == "京都通り" }
      allow(address_index_manager).to receive(:search).with("東京都京都通り").and_return(expected_result)
      results = searcher.search("東京都京都通り")
      expect(results.length).to eq(1)
      expect(results.first.prefecture).to eq("東京都")
      expect(results.first.kyoto_street).to eq("京都通り")
    end

    it 'searches partial match street' do
      expected_result = addresses.select { |a| a.kyoto_street == "京都街" }
      allow(address_index_manager).to receive(:search).with("京都街").and_return(expected_result)
      results = searcher.search("京都街")
      expect(results.length).to eq(1)
      expect(results.first.prefecture).to eq("東京都")
      expect(results.first.kyoto_street).to eq("京都街")
    end

    it 'prioritizes exact matches' do
      kyoto_prefecture = addresses.select { |a| a.prefecture == "京都府" }
      tokyo_kyoto_street = addresses.select { |a| a.prefecture == "東京都" && a.kyoto_street&.include?("京都") }
      expected_results = kyoto_prefecture + tokyo_kyoto_street
      allow(address_index_manager).to receive(:search).with("京都").and_return(expected_results)
      results = searcher.search("京都")
      expect(results.first.prefecture).to eq("京都府")
      expect(results.any? { |r| r.prefecture == "東京都" && r.kyoto_street&.include?("京都") }).to be true
    end

    it 'searches with multiple Kyoto references' do
      allow(address_index_manager).to receive(:search).with("東京都京都通京都タワー").and_return([])
      results = searcher.search("東京都京都通京都タワー")
      expect(results.length).to eq(0)
    end

    it 'searches for addresses containing "中央"' do
      expected_results = addresses.select { |a| a.full_address.include?("中央") }
      allow(address_index_manager).to receive(:search).with("中央").and_return(expected_results)
      results = searcher.search("中央")
      expect(results.length).to eq(2)
      expect(results.map(&:city)).to include("鹿児島市", "千葉市中央区")
    end
  end
end
