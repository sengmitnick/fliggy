require 'rails_helper'

RSpec.describe "Insurances", type: :request do

  let(:user) { create(:user) }
  before { sign_in_as(user) }

  describe "GET /insurances" do
    it "returns http success" do
      get insurances_path
      expect(response).to be_success_with_view_check('index')
    end
  end

  describe "GET /insurances/:id" do
    let(:insurance_product) { create(:insurance_product) }


    it "returns http success" do
      get insurance_path(insurance_product)
      expect(response).to be_success_with_view_check('show')
    end
  end


end
