require 'rails_helper'

RSpec.describe "Trains", type: :request do

  # Uncomment this if controller need authentication
  # let(:user) { create(:user) }
  # before { sign_in_as(user) }

  describe "GET /trains" do
    it "returns http success" do
      get trains_path
      expect(response).to be_success_with_view_check('index')
    end
  end



end
