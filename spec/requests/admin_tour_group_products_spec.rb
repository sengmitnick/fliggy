require 'rails_helper'

RSpec.describe "Admin::TourGroupProducts", type: :request do
  before { admin_sign_in_as(create(:administrator)) }

  describe "GET /admin/tour_group_products" do
    it "returns http success" do
      get admin_tour_group_products_path
      expect(response).to be_success_with_view_check('index')
    end
  end

end
