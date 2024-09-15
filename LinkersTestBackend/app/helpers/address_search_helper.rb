require "csv"
require "set"
require "moji"

module AddressSearchHelper
  def normalize(text)
    Moji.kata_to_hira(text.to_s.unicode_normalize(:nfkc).downcase)
  end

  def generate_2grams(text)
    chars = normalize(text).chars
    (0...chars.length - 1).map { |i| chars[i..i + 1].join }
  end

  def build_inverted_index(addresses)
    index = Hash.new { |h, k| h[k] = Set.new }
    addresses.each_with_index do |address, idx|
      searchable_fields = [
        address.prefecture, address.city, address.town_area,
        address.kyoto_street, address.block_number,
        address.business_name, address.business_address
      ].compact.reject(&:empty?)

      searchable_fields.each do |field|
        generate_2grams(field).each { |gram| index[gram].add(idx) }
      end
    end
    Rails.logger.info "Built index with #{index.size} unique 2-grams"
    index
  end

  def search_results(query, index, addresses)
    Rails.logger.info "Searching for query: #{query}"
    query_grams = generate_2grams(query).uniq

    present_grams = query_grams & index.keys
    return [] if present_grams.empty?

    address_sets = present_grams.map { |gram| index[gram] }
    results_indices = address_sets.reduce(&:intersection)
    results = results_indices.map { |idx| addresses[idx] }

    Rails.logger.info "Found #{results.length} results"
    # Sort results based on the count of query occurrences in the full address
    results.sort_by { |address| -address.full_address.count(query) }
  end

  def load_csv(file_path)
    encoding = 'CP932:UTF-8'
    CSV.read(file_path, encoding: encoding, headers: true).each_with_index.map do |row, index|
      begin
        AddressData.new(
          row['郵便番号']&.to_s&.strip || '',
          row['都道府県']&.to_s&.strip || '',
          row['市区町村']&.to_s&.strip || '',
          row['町域']&.to_s&.strip || '',
          row['京都通り名']&.to_s&.strip || '',
          row['字丁目']&.to_s&.strip || '',
          row['事業所名']&.to_s&.strip || '',
          row['事業所住所']&.to_s&.strip || ''
        )
      rescue => e
        Rails.logger.error("Error processing row #{index + 2}: #{e.message}")
        Rails.logger.error("Row data: #{row.to_h}")
        nil
      end
    end.compact
  end
end
