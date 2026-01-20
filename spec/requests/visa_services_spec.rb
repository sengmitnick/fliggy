require 'rails_helper'

RSpec.describe "Visa services", type: :request do

  let(:user) { create(:user) }
  before { sign_in_as(user) }

  describe "GET /visa_services" do
    it "returns http success" do
      get visa_services_path
      expect(response).to be_success_with_view_check('index')
    end
  end



end
