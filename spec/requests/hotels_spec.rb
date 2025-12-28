require 'rails_helper'

RSpec.describe "Hotels", type: :request do

  # Uncomment this if controller need authentication
  # let(:user) { create(:user) }
  # before { sign_in_as(user) }

  describe "GET /hotels" do
    it "returns http success" do
      get hotels_path
      expect(response).to be_success_with_view_check('index')
    end
  end

  describe "GET /hotels/:id" do
    let(:hotel_record) { create(:hotel) }


    it "returns http success" do
      get hotel_path(hotel_record)
      expect(response).to be_success_with_view_check('show')
    end
  end


end
