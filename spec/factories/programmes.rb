# frozen_string_literal: true

# == Schema Information
#
# Table name: programmes
#
#  id         :bigint           not null, primary key
#  type       :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_programmes_on_type  (type) UNIQUE
#
FactoryBot.define do
  factory :programme do
    type { Programme.types.keys.sample }
    vaccines { [association(:vaccine, programme: instance)] }

    trait :hpv do
      type { "hpv" }
      vaccines { [association(:vaccine, :gardasil_9, programme: instance)] }
    end

    trait :hpv_all_vaccines do
      hpv
      vaccines do
        [
          association(:vaccine, :cervarix, programme: instance),
          association(:vaccine, :gardasil, programme: instance),
          association(:vaccine, :gardasil_9, programme: instance)
        ]
      end
    end

    trait :flu do
      type { "flu" }
      vaccines do
        [
          association(:vaccine, :adjuvanted_quadrivalent, programme: instance),
          association(:vaccine, :fluenz_tetra, programme: instance)
        ]
      end
    end

    trait :flu_all_vaccines do
      flu
      vaccines do
        [
          association(:vaccine, :adjuvanted_quadrivalent, programme: instance),
          association(:vaccine, :cell_quadrivalent, programme: instance),
          association(:vaccine, :fluad_tetra, programme: instance),
          association(:vaccine, :flucelvax_tetra, programme: instance),
          association(:vaccine, :fluenz_tetra, programme: instance),
          association(:vaccine, :quadrivalent_influenza, programme: instance),
          association(
            :vaccine,
            :quadrivalent_influvac_tetra,
            programme: instance
          ),
          association(:vaccine, :supemtek, programme: instance)
        ]
      end
    end

    trait :flu_nasal_only do
      flu
      vaccines { [association(:vaccine, :fluenz_tetra, programme: instance)] }
    end

    trait :menacwy do
      type { "menacwy" }
      vaccines { [association(:vaccine, :menquadfi, programme: instance)] }
    end

    trait :menacwy_all_vaccines do
      type { "menacwy" }
      vaccines do
        [
          association(:vaccine, :menquadfi, programme: instance),
          association(:vaccine, :menveo, programme: instance),
          association(:vaccine, :nimenrix, programme: instance)
        ]
      end
    end

    trait :td_ipv do
      type { "td_ipv" }
      vaccines { [association(:vaccine, :revaxis, programme: instance)] }
    end
  end
end
