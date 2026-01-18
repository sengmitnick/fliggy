require 'rails_helper'

RSpec.describe "Abroad tickets", type: :request do

  let(:user) { create(:user) }
  before { sign_in_as(user) }

  describe "GET /abroad_tickets" do
    it "returns http success" do
      get abroad_tickets_path
      expect(response).to be_success_with_view_check('index')
    end
  end

  describe "GET /abroad_tickets/:id" do
    let(:abroad_ticket_record) { create(:abroad_ticket, user: user) }


    it "returns http success" do
      get abroad_ticket_path(abroad_ticket_record)
      expect(response).to be_success_with_view_check('show')
    end
  end


end
