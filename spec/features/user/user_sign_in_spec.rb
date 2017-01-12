require 'rails_helper'

feature 'user sign in', :dbclean => :after_each do
  given(:user) { create :user }
  scenario 'with valid credentials' do
    visit root_path

    sign_in_with(user.email, user.password)

    expect(page).to have_content('Signed in successfully.')
  end

  scenario 'with invalid password' do
    visit root_path

    sign_in_with(user.email, 'invalid')

    expect(page).to have_content("Invalid email or password.")
  end

  scenario 'with invalid email' do
    visit root_path

    sign_in_with('invalid@email.com', user.password)

    expect(page).to have_content("Invalid email or password.")
  end
end
