require "singleton"

class AddressIndexManager
  include Singleton
  include AddressSearchHelper

  attr_reader :index, :addresses

  def load_or_build_index
    Rails.logger.info "Starting address index initialization..."
    if index_files_exist? && !index_files_outdated?
      load_index
    else
      build_index
    end
    Rails.logger.info "Address index initialization completed."
  end

  def search(query)
    search_results(query, @index, @addresses)
  end

  private

  def index_files_exist?
    File.exist?(index_file_path) && File.exist?(addresses_file_path)
  end

  def index_files_outdated?
    csv_file_path = Rails.root.join(ENV["CSV_FILE_PATH"] || "tmp/zenkoku.csv")
    csv_mtime = File.mtime(csv_file_path)
    index_mtime = File.mtime(index_file_path)
    addresses_mtime = File.mtime(addresses_file_path)

    csv_mtime > index_mtime || csv_mtime > addresses_mtime
  end

  def load_index
    Rails.logger.info "Loading address index from files..."
    @index = MessagePack.unpack(File.binread(index_file_path))
    @index.transform_values! { |indices| Set.new(indices) }
    @addresses = MessagePack.unpack(File.binread(addresses_file_path)).map { |addr| AddressData.new(*addr) }
    Rails.logger.info "Address index loaded successfully."
  end

  def build_index
    Rails.logger.info "Starting to build address index..."
    csv_file_path = Rails.root.join(ENV["CSV_FILE_PATH"] || "tmp/zenkoku.csv")
    Rails.logger.info "Using CSV file: #{csv_file_path}"

    @addresses = load_csv(csv_file_path)
    Rails.logger.info "CSV file loaded. Building inverted index..."

    @index = build_inverted_index(@addresses)
    Rails.logger.info "Inverted index built. Saving to files..."

    save_index
    Rails.logger.info "Address index built and saved successfully."
  end

  def save_index
    index_to_save = @index.transform_values(&:to_a)
    File.open(index_file_path, "wb") do |file|
      file.write(MessagePack.pack(index_to_save))
    end
    File.open(addresses_file_path, "wb") do |file|
      file.write(MessagePack.pack(@addresses.map(&:to_a)))
    end
  end

  def index_file_path
    Rails.root.join("tmp", "inverted_index.msgpack")
  end

  def addresses_file_path
    Rails.root.join("tmp", "addresses.msgpack")
  end
end
