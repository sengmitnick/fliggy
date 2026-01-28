require 'rails_helper'

RSpec.describe "Membership orders", type: :request do

  let(:user) { create(:user) }
  before { sign_in_as(user) }


  describe "GET /membership_orders/:id" do
    let(:membership_order_record) { create(:membership_order, user: user) }


    it "returns http success" do
      get membership_order_path(membership_order_record)
      expect(response).to be_success_with_view_check('show')
    end
  end

  describe "GET /membership_orders/new" do
    let(:membership_product_record) { create(:membership_product) }

    it "returns http success" do
      get new_membership_order_path(product_id: membership_product_record.id)
      expect(response).to be_success_with_view_check('new')
    end
  end
  
end
