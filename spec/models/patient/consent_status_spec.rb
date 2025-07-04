# frozen_string_literal: true

# == Schema Information
#
# Table name: patient_consent_statuses
#
#  id              :bigint           not null, primary key
#  status          :integer          default("no_response"), not null
#  vaccine_methods :integer          default([]), not null, is an Array
#  patient_id      :bigint           not null
#  programme_id    :bigint           not null
#
# Indexes
#
#  index_patient_consent_statuses_on_patient_id_and_programme_id  (patient_id,programme_id) UNIQUE
#  index_patient_consent_statuses_on_status                       (status)
#
# Foreign Keys
#
#  fk_rails_...  (patient_id => patients.id) ON DELETE => cascade
#  fk_rails_...  (programme_id => programmes.id)
#
describe Patient::ConsentStatus do
  subject(:patient_consent_status) do
    build(:patient_consent_status, patient:, programme:)
  end

  let(:patient) { create(:patient) }
  let(:programme) { create(:programme) }

  before { patient.strict_loading!(false) }

  it { should belong_to(:patient) }
  it { should belong_to(:programme) }

  it do
    expect(patient_consent_status).to define_enum_for(:status).with_values(
      %i[no_response given refused conflicts]
    )
  end

  describe "#status" do
    subject { patient_consent_status.tap(&:assign_status).status.to_sym }

    context "with no consent" do
      it { should be(:no_response) }
    end

    context "with an invalidated consent" do
      before { create(:consent, :invalidated, patient:, programme:) }

      it { should be(:no_response) }
    end

    context "with a not provided consent" do
      before { create(:consent, :not_provided, patient:, programme:) }

      it { should be(:no_response) }
    end

    context "with both an invalidated and not provided consent" do
      before do
        create(:consent, :invalidated, patient:, programme:)
        create(:consent, :not_provided, patient:, programme:)
      end

      it { should be(:no_response) }
    end

    context "with a refused consent" do
      before { create(:consent, :refused, patient:, programme:) }

      it { should be(:refused) }
    end

    context "with a given consent" do
      before { create(:consent, :given, patient:, programme:) }

      it { should be(:given) }
    end

    context "with conflicting consent" do
      before do
        create(:consent, :given, patient:, programme:)
        create(
          :consent,
          :refused,
          patient:,
          programme:,
          parent: create(:parent)
        )
      end

      it { should be(:conflicts) }
    end

    context "with two given consents with different methods" do
      before do
        create(
          :consent,
          :given,
          patient:,
          programme:,
          vaccine_methods: %w[injection]
        )
        create(
          :consent,
          :given,
          patient:,
          programme:,
          vaccine_methods: %w[nasal],
          parent: create(:parent)
        )
      end

      it { should be(:conflicts) }
    end

    context "with two given consents, one both and one with injection only" do
      before do
        create(
          :consent,
          :given,
          patient:,
          programme:,
          vaccine_methods: %w[injection]
        )
        create(
          :consent,
          :given,
          patient:,
          programme:,
          vaccine_methods: %w[nasal injection],
          parent: create(:parent)
        )
      end

      it { should be(:given) }
    end

    context "with an invalidated refused and given consent" do
      before do
        create(:consent, :refused, :invalidated, patient:, programme:)
        create(:consent, :given, patient:, programme:)
      end

      it { should be(:given) }
    end

    context "with a refused and given consent from the same parent at different times" do
      before do
        create(
          :consent,
          :refused,
          patient:,
          programme:,
          created_at: 1.day.ago,
          submitted_at: 2.days.ago
        )
        create(
          :consent,
          :given,
          patient:,
          programme:,
          created_at: 2.days.ago,
          submitted_at: 1.day.ago
        )
      end

      it { should be(:given) }
    end

    context "with self-consent" do
      before { create(:consent, :self_consent, :given, patient:, programme:) }

      it { should be(:given) }

      context "and refused parental consent" do
        before { create(:consent, :refused, patient:, programme:) }

        it { should be(:given) }
      end

      context "and conflicting parental consent" do
        before do
          create(:consent, :refused, patient:, programme:)
          create(
            :consent,
            :given,
            patient:,
            programme:,
            parent: create(:parent)
          )
        end

        it { should be(:given) }
      end
    end
  end

  describe "#vaccine_methods" do
    subject { patient_consent_status.tap(&:assign_status).vaccine_methods }

    context "with no consent" do
      it { should be_empty }
    end

    context "with an invalidated consent" do
      before { create(:consent, :invalidated, patient:, programme:) }

      it { should be_empty }
    end

    context "with a not provided consent" do
      before { create(:consent, :not_provided, patient:, programme:) }

      it { should be_empty }
    end

    context "with both an invalidated and not provided consent" do
      before do
        create(:consent, :invalidated, patient:, programme:)
        create(:consent, :not_provided, patient:, programme:)
      end

      it { should be_empty }
    end

    context "with a refused consent" do
      before { create(:consent, :refused, patient:, programme:) }

      it { should be_empty }
    end

    context "with an injection given consent" do
      before do
        create(
          :consent,
          :given,
          patient:,
          programme:,
          vaccine_methods: %w[injection]
        )
      end

      it { should contain_exactly("injection") }
    end

    context "with a nasal given consent" do
      before do
        create(
          :consent,
          :given,
          patient:,
          programme:,
          vaccine_methods: %w[nasal]
        )
      end

      it { should contain_exactly("nasal") }
    end

    context "with both nasal and injection given consent" do
      before do
        create(
          :consent,
          :given,
          patient:,
          programme:,
          vaccine_methods: %w[nasal injection]
        )
      end

      it { should eq(%w[nasal injection]) }
    end

    context "with one parent nasal and one parent both" do
      before do
        create(
          :consent,
          :given,
          patient:,
          programme:,
          vaccine_methods: %w[nasal]
        )
        create(
          :consent,
          :given,
          patient:,
          programme:,
          parent: create(:parent),
          vaccine_methods: %w[nasal injection]
        )
      end

      it { should contain_exactly("nasal") }
    end

    context "with conflicting consent" do
      before do
        create(:consent, :given, patient:, programme:)
        create(
          :consent,
          :refused,
          patient:,
          programme:,
          parent: create(:parent)
        )
      end

      it { should be_empty }
    end

    context "with an invalidated refused and given consent" do
      before do
        create(:consent, :refused, :invalidated, patient:, programme:)
        create(:consent, :given, patient:, programme:)
      end

      it { should contain_exactly("injection") }
    end

    context "with self-consent" do
      before { create(:consent, :self_consent, :given, patient:, programme:) }

      it { should contain_exactly("injection") }

      context "and refused parental consent" do
        before { create(:consent, :refused, patient:, programme:) }

        it { should contain_exactly("injection") }
      end

      context "and conflicting parental consent" do
        before do
          create(:consent, :refused, patient:, programme:)
          create(
            :consent,
            :given,
            patient:,
            programme:,
            parent: create(:parent)
          )
        end

        it { should contain_exactly("injection") }
      end
    end
  end
end
