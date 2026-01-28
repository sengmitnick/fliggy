FactoryBot.define do
  factory :membership_order do
    association :user
    association :membership_product
    quantity { 1 }
    price_cash { 99.00 }
    price_mileage { 1000 }
    total_cash { 99.00 }
    total_mileage { 1000 }
    status { 'pending' }
    sequence(:order_number) { |n| "MS#{Time.current.strftime('%Y%m%d')}#{sprintf('%06d', n)}" }
    shipping_address { '北京市朝阳区某某街道123号' }
    contact_phone { '13800138000' }
    contact_name { '张三' }
  end
end
