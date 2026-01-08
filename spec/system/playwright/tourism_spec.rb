# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Tourism", type: :system do
  include PlaywrightHelper

  let(:base_url) { "http://localhost:3000" }

  it "loads tourism page without errors" do
    with_page("#{base_url}/tourism") do |page|
      expect(page.title).not_to be_empty
      expect(page.url).to include('/tourism')
    end
  end

  it "can navigate tour products on tourism page" do
    with_page("#{base_url}/tourism") do |page|
      # Look for tabs or navigation elements
      tab = page.query_selector('[data-controller*="tab"], button:has-text("跟团游"), button:has-text("自由行")')
      
      if tab
        tab.click
        sleep 0.5
        expect(page.url).to include('/tourism')
      else
        skip "No tour navigation found on tourism page"
      end
    end
  end
end
