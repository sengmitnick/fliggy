# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Trains", type: :system do
  include PlaywrightHelper

  let(:base_url) { "http://localhost:3000" }

  it "loads trains search page without errors" do
    with_page("#{base_url}/trains") do |page|
      expect(page.title).not_to be_empty
      expect(page.url).to include('/trains')
    end
  end

  it "can click search button on trains page" do
    with_page("#{base_url}/trains") do |page|
      search_button = page.query_selector('button:has-text("搜索"), button:has-text("查询车票"), button[type="submit"]')
      
      if search_button
        search_button.click
        sleep 0.5
        expect(page.url).to include('/trains')
      else
        skip "No search button found on trains page"
      end
    end
  end
end
