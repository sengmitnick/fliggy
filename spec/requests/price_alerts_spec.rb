require 'rails_helper'

RSpec.describe "Price alerts", type: :request do

  # Uncomment this if controller need authentication
  # let(:user) { create(:user) }
  # before { sign_in_as(user) }

  describe "GET /price_alerts" do
    it "returns http success" do
      get price_alerts_path
      expect(response).to be_success_with_view_check('index')
    end
  end


  describe "GET /price_alerts/new" do
    it "returns http success" do
      get new_price_alert_path
      expect(response).to be_success_with_view_check('new')
    end
  end
  
end
