FactoryBot.define do
  factory :flight_package do
    # Note: This project uses data packs for all data
    # Factories should not be used to create test data
    # Data is loaded from app/validators/support/data_packs/v1/

    title { "MyString" }
    subtitle { "MyString" }
    price { 9.99 }
    original_price { 9.99 }
    discount_label { "MyString" }
    badge_text { "MyString" }
    badge_color { "MyString" }
    destination { "MyString" }
    image_url { "MyString" }
    valid_days { 1 }
    description { "MyText" }
    features { ["特色1", "特色2"] }
    status { "active" } # Must be 'active' or 'inactive'

  end
end
