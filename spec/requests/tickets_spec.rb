require 'rails_helper'

RSpec.describe "Tickets", type: :request do

  let(:user) { create(:user) }
  before { sign_in_as(user) }


  describe "GET /tickets/:id" do
    let(:ticket_record) { create(:ticket, user: user) }


    it "returns http success" do
      get ticket_path(ticket_record)
      expect(response).to be_success_with_view_check('show')
    end
  end


end
