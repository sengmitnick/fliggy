require 'rails_helper'

RSpec.describe "Flight blind boxes", type: :request do

  # Uncomment this if controller need authentication
  # let(:user) { create(:user) }
  # before { sign_in_as(user) }

  describe "GET /flight_blind_boxes" do
    it "returns http success" do
      get flight_blind_boxes_path
      expect(response).to be_success_with_view_check('index')
    end
  end



end
