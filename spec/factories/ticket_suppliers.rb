FactoryBot.define do
  factory :ticket_supplier do

    ticket_id { 1 }
    supplier_id { 1 }
    current_price { 9.99 }
    original_price { 9.99 }
    stock { 1 }
    discount_info { "MyString" }
    sales_count { 1 }

  end
end
