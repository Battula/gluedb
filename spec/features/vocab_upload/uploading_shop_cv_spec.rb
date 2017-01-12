require 'rails_helper'

feature 'uploading show CV', :dbclean => :after_each do
  given(:premium) do
    PremiumTable.new(
      rate_start_date: Date.new(2014, 1, 1),
      rate_end_date: Date.new(2014, 12, 31),
      age: 53,
      amount: 742.47)
  end
  background do
    user = create :user, :admin
    visit root_path
    sign_in_with(user.email, user.password)

    # Note: The file fixture is dependent on this record.
    plan = Plan.new(coverage_type: 'health', hios_plan_id: '11111111111111-11', year: 2014)
    plan.premium_tables << premium
    plan.save!
    employer = Employer.create!(fein: 111111111)
    plan_year = PlanYear.create!(start_date: Date.new(2014,05,01), end_date: Date.new(2015, 4, 30), employer: employer)
  end

  scenario 'no file is selected' do
    visit new_vocab_upload_path

    choose 'Initial Enrollment'

    click_button "Upload"

    expect(page).not_to have_content 'Uploaded successfully.'
  end

  scenario 'a successful upload' do
    visit new_vocab_upload_path

    choose 'Initial Enrollment'

    file_path = Rails.root + "spec/support/fixtures/shop_enrollment/correct.xml"
    attach_file('vocab_upload_vocab', file_path)

    click_button "Upload"

    expect(page).to have_content 'Uploaded successfully.'
  end

  scenario 'an enrollee\'s premium is incorrect' do
    visit new_vocab_upload_path

    choose 'Initial Enrollment'

    file_path = Rails.root + "spec/support/fixtures/shop_enrollment/incorrect_premium.xml"
    attach_file('vocab_upload_vocab', file_path)

    click_button "Upload"

    expect(page).to have_content 'premium_amount is incorrect'
    expect(page).to have_content 'Failed to Upload.'

  end

  scenario 'premium amount total is incorrect' do
    visit new_vocab_upload_path

    choose 'Initial Enrollment'

    file_path = Rails.root + "spec/support/fixtures/shop_enrollment/incorrect_total.xml"
    attach_file('vocab_upload_vocab', file_path)

    click_button "Upload"

    expect(page).to have_content 'premium_amount_total is incorrect'
    expect(page).to have_content 'Failed to Upload.'
  end

  scenario 'responsible amount is incorrect' do
    visit new_vocab_upload_path

    choose 'Initial Enrollment'

    file_path = Rails.root + "spec/support/fixtures/shop_enrollment/incorrect_responsible.xml"
    attach_file('vocab_upload_vocab', file_path)

    click_button "Upload"

    expect(page).to have_content 'total_responsible_amount is incorrect'
    expect(page).to have_content 'Failed to Upload.'
  end

  feature 'Handling premium not found error' do
    given(:premium) { nil }
    scenario 'premium table is not in the system' do
      visit new_vocab_upload_path

      choose 'Initial Enrollment'

      file_path = Rails.root + "spec/support/fixtures/shop_enrollment/correct.xml"
      attach_file('vocab_upload_vocab', file_path)

      click_button "Upload"

      expect(page).to have_content 'Premium was not found in the system.'
      expect(page).to have_content 'Failed to Upload.'
    end
  end
end
