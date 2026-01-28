require 'rails_helper'

RSpec.describe "Admin::MembershipOrders", type: :request do
  before { admin_sign_in_as(create(:administrator)) }

  describe "GET /admin/membership_orders" do
    it "returns http success" do
      get admin_membership_orders_path
      expect(response).to be_success_with_view_check('index')
    end
  end

end
