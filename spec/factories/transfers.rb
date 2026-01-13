FactoryBot.define do
  factory :transfer do
    association :user
    transfer_type { 'airport_pickup' }
    service_type { 'from_airport' }
    location_from { '虹桥机场T2航站楼' }
    location_to { '静安区南京西路1000号' }
    pickup_datetime { 2.days.from_now }
    flight_number { 'CA1234' }
    train_number { nil }
    passenger_name { '测试用户' }
    passenger_phone { '13800138000' }
    vehicle_type { 'economy_5' }
    provider_name { '阳光出行' }
    license_plate { '粤BAE8055' }
    driver_name { '张师傅' }
    driver_status { 'pending' }
    total_price { 120.0 }
    discount_amount { 0.0 }
    status { 'pending' }
  end
end
