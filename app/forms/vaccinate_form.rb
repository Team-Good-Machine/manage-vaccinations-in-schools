# frozen_string_literal: true

class VaccinateForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attr_accessor :patient_session, :programme, :current_user, :todays_batch

  attribute :pre_screening_confirmed, :boolean
  attribute :pre_screening_notes, :string

  attribute :administered, :boolean
  attribute :delivery_method, :string
  attribute :delivery_site, :string
  attribute :dose_sequence, :integer
  attribute :programme_id, :integer

  validates :administered, inclusion: [true, false]
  validates :pre_screening_notes, length: { maximum: 1000 }

  with_options if: :administered do
    validates :pre_screening_confirmed, presence: true
    validates :delivery_method, presence: true
    validates :delivery_site, presence: true
  end

  def save(draft_vaccination_record:)
    return nil if invalid?

    return false unless pre_screening.save

    draft_vaccination_record.reset!

    if administered
      draft_vaccination_record.outcome = "administered"

      if delivery_site != "other"
        draft_vaccination_record.delivery_method = delivery_method
        draft_vaccination_record.delivery_site = delivery_site
      end
    end

    draft_vaccination_record.batch_id = todays_batch&.id
    draft_vaccination_record.dose_sequence = dose_sequence
    draft_vaccination_record.patient_id = patient_session.patient_id
    draft_vaccination_record.performed_at = Time.current
    draft_vaccination_record.performed_by_user = current_user
    draft_vaccination_record.performed_ods_code = organisation.ods_code
    draft_vaccination_record.programme = programme
    draft_vaccination_record.session_id = patient_session.session_id

    draft_vaccination_record.save # rubocop:disable Rails/SaveBang
  end

  def ask_not_taking_medication? = programme.doubles?

  def ask_not_pregnant? = programme.td_ipv?

  private

  delegate :organisation, to: :patient_session

  def pre_screening
    @pre_screening ||=
      patient_session.pre_screenings.build(
        feeling_well: true,
        knows_vaccination: true,
        no_allergies: true,
        not_already_had: true,
        not_pregnant: true,
        not_taking_medication: true,
        notes: pre_screening_notes,
        performed_by: current_user,
        programme:,
        session_date_id:
      )
  end

  def session_date_id
    patient_session.session.session_dates.today.first&.id
  end
end
