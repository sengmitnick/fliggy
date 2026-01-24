FactoryBot.define do
  factory :activity_order do

    association :user
    association :attraction_activity
    passenger_name { "张三" }
    contact_phone { "13800138000" }
    visit_date { Date.today + 1.day }
    quantity { 1 }
    total_price { 150 }
    status { "pending" }
    order_number { "AO#{Time.current.strftime('%Y%m%d%H%M%S')}#{rand(10000..99999)}" }

  end
end
