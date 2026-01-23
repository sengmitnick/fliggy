require 'rails_helper'

RSpec.describe "Chartered tours", type: :request do

  let(:user) { create(:user) }
  before { sign_in_as(user) }

  describe "GET /chartered_tours" do
    it "returns http success" do
      get chartered_tours_path
      expect(response).to be_success_with_view_check('index')
    end
  end



end
