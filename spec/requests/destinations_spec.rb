require 'rails_helper'

RSpec.describe "Destinations", type: :request do

  # Uncomment this if controller need authentication
  # let(:user) { create(:user) }
  # before { sign_in_as(user) }

  describe "GET /destinations" do
    it "returns http success" do
      get destinations_path
      expect(response).to be_success_with_view_check('index')
    end
  end

  describe "GET /destinations/:id" do
    let(:destination_record) { create(:destination) }


    it "returns http success" do
      get destination_path(destination_record)
      expect(response).to be_success_with_view_check('show')
    end
  end


end
