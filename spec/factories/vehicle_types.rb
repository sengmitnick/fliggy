FactoryBot.define do
  factory :vehicle_type do
    name { '别克GL8商务车' }
    category { '7座' }  # Valid: 5座, 7座, 巴士
    level { '舒适' }     # Valid: 经济, 舒适, 豪华
    seats { 7 }
    luggage_capacity { 3 }
    hourly_price_6h { 600.0 }
    hourly_price_8h { 800.0 }
    included_mileage { 100 }
    image_url { 'https://images.unsplash.com/photo-1519641471654-76ce0107ad1b?w=800' }
  end
end
