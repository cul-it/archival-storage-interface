require 'rails_helper'

RSpec.feature "Unauthorized Access", type: :feature do
  scenario "search for Africana facet without logging in first" do
    visit "/?f%5Bdepositor_tesi%5D%5B%5D=africana"

    expect(page).to have_text("Forgot your password?")
  end
end
