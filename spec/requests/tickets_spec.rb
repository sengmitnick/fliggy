require 'rails_helper'

RSpec.describe "Tickets", type: :request do

  let(:user) { create(:user) }
  before { sign_in_as(user) }


  describe "GET /tickets/:id" do
    let(:attraction) { create(:attraction) }  # 显式创建 attraction
    let(:ticket_record) { create(:ticket, attraction: attraction) }  # 关联到同一个 attraction

    it "returns http success" do
      get ticket_path(ticket_record)
      # tickets#show redirects to attraction_path, so expect redirect
      expect(response).to have_http_status(:redirect)
      expect(response).to redirect_to(attraction_path(attraction))  # 使用显式创建的 attraction
    end
  end


end
