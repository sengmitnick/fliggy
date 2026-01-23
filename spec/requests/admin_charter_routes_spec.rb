require 'rails_helper'

RSpec.describe "Admin::CharterRoutes", type: :request do
  before { admin_sign_in_as(create(:administrator)) }

  describe "GET /admin/charter_routes" do
    it "returns http success" do
      get admin_charter_routes_path
      expect(response).to be_success_with_view_check('index')
    end
  end

end
