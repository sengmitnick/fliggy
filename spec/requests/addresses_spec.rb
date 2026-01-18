require 'rails_helper'

RSpec.describe "Addresses", type: :request do

  let(:user) { create(:user) }
  before { sign_in_as(user) }

  describe "GET /addresses" do
    it "returns http success" do
      get addresses_path
      expect(response).to be_success_with_view_check('index')
    end
  end


  describe "GET /addresses/new" do
    it "returns http success" do
      get new_address_path
      expect(response).to be_success_with_view_check('new')
    end
  end
  
  describe "GET /addresses/:id/edit" do
    let(:address_record) { create(:address, user: user) }


    it "returns http success" do
      get edit_address_path(address_record)
      expect(response).to be_success_with_view_check('edit')
    end
  end
end
