require 'rails_helper'

RSpec.describe "Tickets", type: :request do

  let(:user) { create(:user) }
  before { sign_in_as(user) }


  describe "GET /tickets/:id" do
    let(:ticket_record) { create(:ticket) }


    it "returns http success" do
      get ticket_path(ticket_record)
      # tickets#show redirects to attraction_path, so expect redirect
      expect(response).to have_http_status(:redirect)
      expect(response).to redirect_to(attraction_path(ticket_record.attraction))
    end
  end


end
