require 'rails_helper'

RSpec.describe "Visa orders", type: :request do

  let(:user) { create(:user) }
  before { sign_in_as(user) }


  describe "GET /visa_orders/:id" do
    let(:visa_order_record) { create(:visa_order, user: user) }


    it "returns http success" do
      get visa_order_path(visa_order_record)
      expect(response).to be_success_with_view_check('show')
    end
  end

  describe "GET /visa_orders/new" do
    it "returns http success" do
      get new_visa_order_path
      expect(response).to be_success_with_view_check('new')
    end
  end
  
end
