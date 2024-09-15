class AddressSearcher
  def initialize(index_manager = AddressIndexManager.instance)
    @index_manager = index_manager
  end

  def search(query)
    @index_manager.search(query)
  end
end