require 'rails_helper'

feature 'User sign up', :dbclean => :after_each do
  scenario 'will valid info' do
    user = build :user

    sign_up_as user

    expect(page).to have_content 'Please sign in'
  end

  scenario 'without providing an Email' do
    user = build :user, :without_email

    sign_up_as user

    expect(page).to have_content "Email can't be blank"
  end

  scenario 'without providing an Password' do
    user = build :user, :without_password

    sign_up_as user

    expect(page).to have_content "Password can't be blank"
  end
end
