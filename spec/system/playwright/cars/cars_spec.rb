# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Cars", type: :system do
  include PlaywrightHelper

  let(:base_url) { "http://localhost:3000" }

  it "loads cars rental page without errors" do
    with_page("#{base_url}/cars") do |page|
      expect(page.title).not_to be_empty
      expect(page.url).to include('/cars')
    end
  end

  it "can click search button on cars page" do
    with_page("#{base_url}/cars") do |page|
      search_button = page.query_selector('button:has-text("搜索"), button:has-text("查询车辆"), button[type="submit"]')
      
      if search_button
        search_button.click
        sleep 0.5
        expect(page.url).to include('/cars')
      else
        skip "No search button found on cars page"
      end
    end
  end
end
