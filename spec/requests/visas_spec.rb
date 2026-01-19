require 'rails_helper'

RSpec.describe "Visas", type: :request do

  let(:user) { create(:user) }
  before { sign_in_as(user) }

  describe "GET /visas" do
    it "returns http success" do
      get visas_path
      expect(response).to be_success_with_view_check('index')
    end
  end

  describe "GET /visas/:id" do
    # Note: visas#show displays a Country with its visa_products, not a "Visa" model
    # Fallback: Create minimal Country if none exists (temporary until data pack is ready)
    let(:country) { Country.first || Country.create!(name: "泰国", code: "TH", region: "东南亚") }


    it "returns http success" do
      get visa_path(country)
      expect(response).to be_success_with_view_check('show')
    end
  end


end
