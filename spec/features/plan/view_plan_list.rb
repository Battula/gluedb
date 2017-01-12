require 'rails_helper'

feature 'viewing list of plans', :dbclean => :after_each do
  scenario 'when there are many plans' do
    user = create :user
    visit root_path
    sign_in_with(user.email, user.password)

    plan = create :plan

    visit('/plans')

    expect(page).to have_content(plan.name)
  end
end

