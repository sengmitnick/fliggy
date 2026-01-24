FactoryBot.define do
  factory :ticket_order do
    association :user
    association :ticket
    association :passenger
    supplier_id { nil }
    contact_phone { "13800138000" }
    visit_date { Date.today + 1.day }
    quantity { 2 }
    total_price { 160 }
    status { "pending" }
    order_number { "TO#{Time.current.strftime('%Y%m%d%H%M%S')}#{rand(10000..99999)}" }
  end
end
