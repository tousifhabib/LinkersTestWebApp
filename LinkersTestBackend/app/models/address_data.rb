require "csv"
require "msgpack"

AddressData = Struct.new(
  :postal_code, :prefecture, :city, :town_area, :kyoto_street,
  :block_number, :business_name, :business_address
) do
  def full_address
    @full_address ||= [
      prefecture, city, town_area, kyoto_street, block_number,
      business_name, business_address
    ].compact.reject(&:empty?).join(" ")
  end

  def formatted_output
    "#{postal_code} #{full_address}"
  end

  def to_s
    formatted_output
  end

  def inspect
    "#<AddressData #{formatted_output}>"
  end

  def to_h
    {
      postal_code: postal_code,
      prefecture: prefecture,
      city: city,
      town_area: town_area,
      kyoto_street: kyoto_street,
      block_number: block_number,
      business_name: business_name,
      business_address: business_address
    }
  end

  def to_a
    [
      postal_code, prefecture, city, town_area, kyoto_street,
      block_number, business_name, business_address
    ]
  end
end
