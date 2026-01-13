require 'rails_helper'

RSpec.describe "Abroad ticket orders", type: :request do

  let(:user) { create(:user) }
  before { sign_in_as(user) }


  describe "GET /abroad_ticket_orders/:id" do
    let(:abroad_ticket_order_record) { create(:abroad_ticket_order, user: user) }


    it "returns http success" do
      get abroad_ticket_order_path(abroad_ticket_order_record)
      expect(response).to be_success_with_view_check('show')
    end
  end

  describe "GET /abroad_ticket_orders/new" do
    let(:abroad_ticket) { create(:abroad_ticket) }

    it "returns http success" do
      get new_abroad_ticket_order_path(abroad_ticket_id: abroad_ticket.id)
      expect(response).to be_success_with_view_check('new')
    end
  end
  
end
