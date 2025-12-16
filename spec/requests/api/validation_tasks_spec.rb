require 'rails_helper'

RSpec.describe "Validation tasks", type: :request do

  # Uncomment this if controller need authentication
  # let(:user) { create(:user) }
  # before { api_sign_in_as(user) }

  describe "GET /validation_tasks" do
    it "returns http success" do
      get api_validation_tasks_path
      expect(response).to have_http_status(:success)
      expect(response.content_type).to match(/json/)
    end
  end

  describe "GET /validation_tasks/:id" do
    let(:validation_task_record) { create(:validation_task) }


    it "returns http success" do
      get api_validation_task_path(validation_task_record)
      expect(response).to have_http_status(:success)
      expect(response.content_type).to match(/json/)
    end
  end

  describe "GET /validation_tasks/new" do
    it "returns http success" do
      get new_api_validation_task_path
      expect(response).to have_http_status(:success)
    end
  end
  
  describe "GET /validation_tasks/:id/edit" do
    let(:validation_task_record) { create(:validation_task) }


    it "returns http success" do
      get edit_api_validation_task_path(validation_task_record)
      expect(response).to have_http_status(:success)
    end
  end
end
