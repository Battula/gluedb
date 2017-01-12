require 'rails_helper'

feature 'viewing list of people', :dbclean => :after_each do
  scenario 'when there are many people' do
    user = create :user
    visit root_path
    sign_in_with(user.email, user.password)

    people = create_many_people(3)

    visit people_path

    people.each do |person|
      expect(page).to have_content(person.name_last)
    end
  end
end

