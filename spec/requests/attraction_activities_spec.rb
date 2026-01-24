require 'rails_helper'

RSpec.describe "Attraction activities", type: :request do

  let(:user) { create(:user) }
  before { sign_in_as(user) }


  describe "GET /attraction_activities/:id" do
    let(:attraction_activity_record) { create(:attraction_activity, user: user) }


    it "returns http success" do
      get attraction_activity_path(attraction_activity_record)
      expect(response).to be_success_with_view_check('show')
    end
  end


end
