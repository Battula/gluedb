require 'rails_helper'

feature 'editing a person', :dbclean => :after_each do
  background do
    @person = create :person
    user = create :user, :admin
    visit root_path
    sign_in_with(user.email, user.password)
  end

  # scenario 'changing name' do
  #   original_name = @person.name_full
  #   new_name = 'Sophie X Loaf'

  #   visit people_path

  #   click_link original_name
  #   click_link 'Edit'

  #   fill_in 'person_name_first', with: 'Sophie'
  #   fill_in 'person_name_middle', with: 'X'
  #   fill_in 'person_name_last', with: 'Loaf'

  #   click_button 'Continue'

  #   user_sees_change_overview
  # end
end

def user_sees_change_overview
  expect(page).to have_content 'Person Changes'
  #TODO assert more details
end
