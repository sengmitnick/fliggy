require 'rails_helper'

RSpec.describe "Deep travels", type: :request do

  # Uncomment this if controller need authentication
  # let(:user) { create(:user) }
  # before { sign_in_as(user) }

  describe "GET /deep_travels" do
    it "returns http success" do
      get deep_travels_path
      expect(response).to be_success_with_view_check('index')
    end
  end



end
