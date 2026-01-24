require 'rails_helper'

RSpec.describe "Admin::AttractionActivities", type: :request do
  before { admin_sign_in_as(create(:administrator)) }

  describe "GET /admin/attraction_activities" do
    it "returns http success" do
      get admin_attraction_activities_path
      expect(response).to be_success_with_view_check('index')
    end
  end

end
