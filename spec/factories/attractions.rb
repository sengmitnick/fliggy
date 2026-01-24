FactoryBot.define do
  factory :attraction do
    name { "MyString" }
    province { "湖北" }
    city { "武汉" }
    district { "武昌区" }
    address { "MyText" }
    latitude { 30.5450 }
    longitude { 114.2968 }
    rating { 4.5 }
    review_count { 0 }
    opening_hours { "09:00-17:00" }
    phone { "027-12345678" }
    description { "MyText" }
    slug { nil }
  end
end
