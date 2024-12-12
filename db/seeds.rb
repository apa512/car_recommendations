BRANDS_DATA = JSON.parse(File.read('db/brands.json'))
CARS_DATA = JSON.parse(File.read('db/cars.json'))

BRANDS = BRANDS_DATA.each.with_object({}) do |brand_item, memo|
  brand_name = brand_item['name']
  memo[brand_name] = Brand.find_or_create_by!(id: brand_item['id']) do |brand|
    brand.name = brand_name
  end
end

CARS_DATA.each do |car_item|
  Car.find_or_create_by!(id: car_item['id']) do |car|
    car.model = car_item['model']
    car.brand = BRANDS[car_item['brand_name']]
    car.price = car_item['price']
  end
end

User.create!(
  email: 'example@mail.com',
  preferred_price_range: 35_000...40_000,
  preferred_brands: [BRANDS['Alfa Romeo'], BRANDS['Volkswagen']],
)
