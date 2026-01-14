require 'rails_helper'

RSpec.describe "Transfers", type: :request do

  let(:user) { create(:user) }
  before { sign_in_as(user) }

  describe "GET /transfers" do
    it "returns http success" do
      get transfers_path
      expect(response).to be_success_with_view_check('index')
    end
  end

  describe "GET /transfers/:id" do
    let(:transfer_record) { create(:transfer, user: user) }


    it "returns http success" do
      get transfer_path(transfer_record)
      expect(response).to be_success_with_view_check('show')
    end
  end

  describe "GET /transfers/search_flights" do
    it "returns http success" do
      get search_flights_transfers_path
      expect(response).to be_success_with_view_check('search_flights')
    end
  end
  
end
