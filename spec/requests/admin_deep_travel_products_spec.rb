require 'rails_helper'

RSpec.describe "Admin::DeepTravelProducts", type: :request do
  before { admin_sign_in_as(create(:administrator)) }

  describe "GET /admin/deep_travel_products" do
    it "returns http success" do
      get admin_deep_travel_products_path
      expect(response).to be_success_with_view_check('index')
    end
  end

end
