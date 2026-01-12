FactoryBot.define do
  factory :user_coupon do

    user_id { 1 }
    abroad_coupon_id { 1 }
    status { "MyString" }
    claimed_at { Time.current }
    used_at { Time.current }
    expires_at { Time.current }

  end
end
