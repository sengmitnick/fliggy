require 'rails_helper'

RSpec.describe "Insurance orders", type: :request do

  let(:user) { create(:user) }
  before { sign_in_as(user) }


  describe "GET /insurance_orders/:id" do
    let(:insurance_order_record) { create(:insurance_order, user: user) }


    it "returns http success" do
      get insurance_order_path(insurance_order_record)
      expect(response).to be_success_with_view_check('show')
    end
  end

  describe "GET /insurance_orders/new" do
    let(:insurance_product) { create(:insurance_product) }
    it "returns http success" do
      get new_insurance_order_path(insurance_product_id: insurance_product.id, start_date: Date.today, end_date: Date.today + 7)
      expect(response).to be_success_with_view_check('new')
    end
  end
  
end
