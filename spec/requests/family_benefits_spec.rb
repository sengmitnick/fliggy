require 'rails_helper'

RSpec.describe "Family benefits", type: :request do

  # Uncomment this if controller need authentication
  # let(:user) { create(:user) }
  # before { sign_in_as(user) }

  describe "GET /family_benefits" do
    it "returns http success" do
      get family_benefits_path
      expect(response).to be_success_with_view_check('index')
    end
  end



end
