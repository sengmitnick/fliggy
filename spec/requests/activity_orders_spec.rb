require 'rails_helper'

RSpec.describe "Activity orders", type: :request do

  let(:user) { create(:user) }
  before { sign_in_as(user) }


  describe "GET /activity_orders/:id" do
    let(:activity_order_record) { create(:activity_order, user: user) }


    it "returns http success" do
      get activity_order_path(activity_order_record)
      expect(response).to be_success_with_view_check('show')
    end
  end

  describe "GET /activity_orders/new" do
    let(:activity) { create(:attraction_activity) }
    
    it "returns http success" do
      get new_attraction_activity_activity_order_path(activity)
      expect(response).to be_success_with_view_check('new')
    end
  end
  
end
