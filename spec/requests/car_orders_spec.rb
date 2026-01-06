require 'rails_helper'

RSpec.describe "Car orders", type: :request do

  # Uncomment this if controller need authentication
  # let(:user) { create(:user) }
  # before { sign_in_as(user) }



  describe "GET /car_orders/new" do
    it "returns http success" do
      get new_car_order_path
      expect(response).to be_success_with_view_check('new')
    end
  end
  
end
