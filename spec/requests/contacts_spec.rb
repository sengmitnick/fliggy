require 'rails_helper'

RSpec.describe "Contacts", type: :request do

  let(:user) { create(:user) }
  before { sign_in_as(user) }

  describe "GET /contacts" do
    it "returns http success" do
      get contacts_path
      expect(response).to be_success_with_view_check('index')
    end
  end


  describe "GET /contacts/new" do
    it "returns http success" do
      get new_contact_path
      expect(response).to be_success_with_view_check('new')
    end
  end
  
  describe "GET /contacts/:id/edit" do
    let(:contact_record) { create(:contact, user: user) }


    it "returns http success" do
      get edit_contact_path(contact_record)
      expect(response).to be_success_with_view_check('edit')
    end
  end
end
