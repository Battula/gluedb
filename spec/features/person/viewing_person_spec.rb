require 'rails_helper'

feature 'viewing a person', :dbclean => :after_each do
  scenario 'by clicking on the person name in list' do
    user = create :user
    visit root_path
    sign_in_with(user.email, user.password)

    person = create :person

    visit people_path
    click_link person.name_full

    expect(page).to have_content(person.name_full)
  end
end
