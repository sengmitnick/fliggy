require 'rails_helper'

RSpec.describe "Admin::Tickets", type: :request do
  before { admin_sign_in_as(create(:administrator)) }

  describe "GET /admin/tickets" do
    it "returns http success" do
      get admin_tickets_path
      expect(response).to be_success_with_view_check('index')
    end
  end

end
