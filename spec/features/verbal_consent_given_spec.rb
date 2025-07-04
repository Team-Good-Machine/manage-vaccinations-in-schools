# frozen_string_literal: true

describe "Verbal consent" do
  scenario "Given" do
    given_i_am_signed_in

    when_i_record_that_verbal_consent_was_given
    then_an_email_is_sent_to_the_parent_confirming_their_consent
    and_a_text_is_sent_to_the_parent_confirming_their_consent
    and_the_patients_status_is_safe_to_vaccinate
    and_i_can_see_the_consent_response_details
  end

  def given_i_am_signed_in
    programmes = [create(:programme, :hpv)]
    organisation = create(:organisation, :with_one_nurse, programmes:)
    @session = create(:session, organisation:, programmes:)

    @parent = create(:parent)
    @patient = create(:patient, session: @session, parents: [@parent])

    sign_in organisation.users.first
  end

  def when_i_record_that_verbal_consent_was_given
    visit session_consent_path(@session)
    click_link @patient.full_name
    click_button "Get verbal consent"

    # Who are you trying to get consent from?
    click_button "Continue"
    expect(page).to have_content(
      "Choose who you are trying to get consent from"
    )

    choose "#{@parent.full_name} (#{@patient.parent_relationships.first.label})"
    click_button "Continue"

    # Details for parent or guardian
    expect(page).to have_content(
      "Details for #{@parent.full_name} (#{@patient.parent_relationships.first.label})"
    )
    # don't change any details
    click_button "Continue"

    # How was the response given?
    choose "By phone"
    click_button "Continue"

    # Do they agree?
    choose "Yes, they agree"
    click_button "Continue"

    # Health questions
    find_all(".nhsuk-fieldset")[0].choose "No"
    find_all(".nhsuk-fieldset")[1].choose "No"
    find_all(".nhsuk-fieldset")[2].choose "No"
    find_all(".nhsuk-fieldset")[3].choose "No"
    click_button "Continue"

    choose "Yes, it’s safe to vaccinate"
    click_button "Continue"

    # Confirm
    expect(page).to have_content("Check and confirm answers")
    expect(page).to have_content(["Response method", "By phone"].join)
    click_button "Confirm"

    # Back on the consent responses page
    expect(page).to have_content("Consent recorded for #{@patient.full_name}")
  end

  def and_the_patients_status_is_safe_to_vaccinate
    click_link @patient.full_name, match: :first
    expect(page).to have_content("Safe to vaccinate")
  end

  def and_i_can_see_the_consent_response_details
    click_link @parent.full_name

    expect(page).to have_content("Consent response from #{@parent.full_name}")
    expect(page).to have_content(
      ["Response date", Date.current.to_fs(:long)].join
    )
    expect(page).to have_content(["Decision", "Consent given"].join)
    expect(page).to have_content(["Response method", "By phone"].join)

    expect(page).to have_content(["Full name", @patient.full_name].join)
    expect(page).to have_content(
      ["Date of birth", @patient.date_of_birth.to_fs(:long)].join
    )
    expect(page).to have_content(["School", @patient.school.name].join)

    expect(page).to have_content(["Name", @parent.full_name].join)
    expect(page).to have_content(
      ["Relationship", @patient.parent_relationships.first.label].join
    )
    expect(page).to have_content(["Email address", @parent.email].join("\n"))
    expect(page).to have_content(["Phone number", @parent.phone].join("\n"))

    expect(page).to have_content("Answers to health questions")
    expect(page).to have_content(
      "#{@patient.parent_relationships.first.label} responded: No",
      count: 4
    )
  end

  def then_an_email_is_sent_to_the_parent_confirming_their_consent
    expect_email_to(@parent.email, :consent_confirmation_given)
  end

  def and_a_text_is_sent_to_the_parent_confirming_their_consent
    expect_sms_to(@parent.phone, :consent_confirmation_given)
  end
end
