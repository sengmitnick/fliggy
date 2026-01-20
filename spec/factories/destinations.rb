FactoryBot.define do
  factory :destination do
    # Note: This project uses data packs for all data
    # Factories should not be used to create test data
    # Data is loaded from app/validators/support/data_packs/v1/
    
    sequence(:name) { |n| "City#{n}" }
    region { "广东" }
    description { "A beautiful destination" }
    image_url { nil }
    is_hot { true }
  end
end
