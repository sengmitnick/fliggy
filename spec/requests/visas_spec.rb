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
    let(:visa_record) { create(:visa, user: user) }


    it "returns http success" do
      get visa_path(visa_record)
      expect(response).to be_success_with_view_check('show')
    end
  end


end
