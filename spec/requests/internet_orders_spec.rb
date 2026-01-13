require 'rails_helper'

RSpec.describe "Internet orders", type: :request do

  let(:user) { create(:user) }
  before { sign_in_as(user) }



  describe "GET /internet_orders/new" do
    it "returns http success" do
      get new_internet_order_path
      expect(response).to be_success_with_view_check('new')
    end
  end
  
end
