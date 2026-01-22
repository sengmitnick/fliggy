FactoryBot.define do
  factory :insurance_order do
    association :user
    association :insurance_product
    
    sequence(:order_number) { |n| "INS#{Time.current.strftime('%Y%m%d')}#{format('%06d', n)}" }
    source { 'standalone' }
    
    start_date { Date.current }
    end_date { Date.current + 7.days }
    days { 8 }
    
    destination { '北京' }
    destination_type { 'domestic' }
    
    insured_persons do
      [
        {
          name: '张三',
          id_number: '110101199001011234',
          phone: '13800138000'
        }
      ]
    end
    
    unit_price { 50.00 }
    quantity { 1 }
    total_price { 50.00 }
    
    status { 'pending' }
    paid_at { nil }
    
    related_booking { nil }
    
    sequence(:policy_number) { |n| "POL-#{Time.current.strftime('%Y%m%d')}-#{format('%04d', n)}" }
    policy_file_url { nil }
    
    trait :paid do
      status { 'paid' }
      paid_at { Time.current }
    end
    
    trait :effective do
      status { 'effective' }
      paid_at { 1.day.ago }
      start_date { Date.current }
      end_date { Date.current + 7.days }
    end
    
    trait :expired do
      status { 'expired' }
      paid_at { 30.days.ago }
      start_date { 20.days.ago }
      end_date { 10.days.ago }
    end
    
    trait :cancelled do
      status { 'cancelled' }
    end
    
    trait :embedded do
      source { 'embedded' }
      association :related_booking, factory: :booking
    end
    
    trait :with_multiple_travelers do
      quantity { 3 }
      insured_persons do
        [
          { name: '张三', id_number: '110101199001011234', phone: '13800138000' },
          { name: '李四', id_number: '110101199002022345', phone: '13800138001' },
          { name: '王五', id_number: '110101199003033456', phone: '13800138002' }
        ]
      end
      total_price { unit_price * 3 }
    end
  end
end
