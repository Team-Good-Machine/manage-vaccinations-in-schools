# frozen_string_literal: true

namespace :vaccines do
  desc "Seed the vaccine table from the built-in vaccine data."
  task :seed, %i[type] => :environment do |_task, args|
    type = args[:type]

    all_data = YAML.load_file(Rails.root.join("config/vaccines.yml"))

    all_data.each_value do |data|
      next if type.present? && data["type"] != type

      programme = Programme.find_or_create_by!(type: data["type"])

      vaccine =
        Vaccine.find_or_initialize_by(
          snomed_product_code: data["snomed_product_code"]
        )

      vaccine.brand = data["brand"]
      vaccine.discontinued = data.fetch("discontinued", false)
      vaccine.dose_volume_ml = data["dose_volume_ml"]
      vaccine.manufacturer = data["manufacturer"]
      vaccine.method = data["method"]
      vaccine.nivs_name = data["nivs_name"]
      vaccine.snomed_product_term = data["snomed_product_term"]
      vaccine.programme = programme

      vaccine.save!

      next if vaccine.health_questions.exists?

      ActiveRecord::Base.transaction do
        if programme.flu?
          create_flu_health_questions(vaccine)
        elsif programme.hpv?
          create_hpv_health_questions(vaccine)
        elsif programme.menacwy?
          create_menacwy_health_questions(vaccine)
        elsif programme.td_ipv?
          create_td_ipv_health_questions(vaccine)
        else
          raise UnsupportedProgramme, programme
        end
      end
    end
  end
end

def create_flu_health_questions(vaccine)
  asthma =
    vaccine.health_questions.create!(
      title: "Has your child been diagnosed with asthma?"
    )

  asthma_steroids =
    vaccine.health_questions.create!(
      title: "Does your child take steroid tablets for their asthma?"
    )

  asthma_intensive_care =
    vaccine.health_questions.create!(
      title:
        "Has your child ever been admitted to intensive care because of their asthma?"
    )

  immune_system =
    vaccine.health_questions.create!(
      title:
        "Does your child have a disease or treatment that severely affects their immune system?"
    )

  household_immune_system =
    vaccine.health_questions.create!(
      title:
        "Is anyone in your child’s household currently having treatment that severely affects their immune system?"
    )

  egg_allergy =
    vaccine.health_questions.create!(
      title:
        "Has your child ever been admitted to intensive care due to an allergic reaction to egg?"
    )

  allergies =
    vaccine.health_questions.create!(
      title: "Does your child have any allergies to medication?"
    )

  medical_conditions =
    vaccine.health_questions.create!(
      title:
        "Does your child have any medical conditions for which they receive treatment?"
    )

  aspirin =
    vaccine.health_questions.create!(
      title: "Does your child take regular aspirin?",
      hint: "Also known as Salicylate therapy"
    )

  flu_previously =
    vaccine.health_questions.create!(
      title: "Has your child had a flu vaccination in the last 3 months?"
    )

  extra_support =
    vaccine.health_questions.create!(
      title: "Does your child need extra support during vaccination sessions?",
      hint: "For example, they’re autistic, or extremely anxious"
    )

  asthma.update!(
    follow_up_question: asthma_steroids,
    next_question: immune_system
  )
  asthma_steroids.update!(next_question: asthma_intensive_care)
  asthma_intensive_care.update!(next_question: immune_system)

  immune_system.update!(next_question: household_immune_system)
  household_immune_system.update!(next_question: egg_allergy)
  egg_allergy.update!(next_question: allergies)
  allergies.update!(next_question: medical_conditions)
  medical_conditions.update!(next_question: aspirin)
  aspirin.update!(next_question: flu_previously)
  flu_previously.update!(next_question: extra_support)
end

def create_hpv_health_questions(vaccine)
  severe_allergies =
    vaccine.health_questions.create!(
      title: "Does your child have any severe allergies?"
    )

  medical_conditions =
    vaccine.health_questions.create!(
      title:
        "Does your child have any medical conditions for which they receive treatment?"
    )

  severe_reaction =
    vaccine.health_questions.create!(
      title:
        "Has your child ever had a severe reaction to any medicines, including vaccines?"
    )

  extra_support =
    vaccine.health_questions.create!(
      title: "Does your child need extra support during vaccination sessions?",
      hint: "For example, they’re autistic, or extremely anxious"
    )

  severe_allergies.update!(next_question: medical_conditions)
  medical_conditions.update!(next_question: severe_reaction)
  severe_reaction.update!(next_question: extra_support)
end

def create_menacwy_health_questions(vaccine)
  bleeding_disorder =
    vaccine.health_questions.create!(
      title:
        "Does your child have a bleeding disorder or another medical condition they receive treatment for?"
    )

  severe_allergies =
    vaccine.health_questions.create!(
      title: "Does your child have any severe allergies?"
    )

  severe_reaction =
    vaccine.health_questions.create!(
      title:
        "Has your child ever had a severe reaction to any medicines, including vaccines?"
    )

  extra_support =
    vaccine.health_questions.create!(
      title: "Does your child need extra support during vaccination sessions?",
      hint: "For example, they’re autistic, or extremely anxious"
    )

  menacwy_previously =
    vaccine.health_questions.create!(
      title:
        "Has your child had a meningitis (MenACWY) vaccination in the last 5 years?",
      hint:
        "It’s usually given once in Year 9 or 10. Some children may have had it before travelling abroad."
    )

  bleeding_disorder.update!(next_question: severe_allergies)
  severe_allergies.update!(next_question: severe_reaction)
  severe_reaction.update!(next_question: extra_support)
  extra_support.update!(next_question: menacwy_previously)
end

def create_td_ipv_health_questions(vaccine)
  bleeding_disorder =
    vaccine.health_questions.create!(
      title:
        "Does your child have a bleeding disorder or another medical condition they receive treatment for?"
    )

  severe_allergies =
    vaccine.health_questions.create!(
      title: "Does your child have any severe allergies?"
    )

  severe_reaction =
    vaccine.health_questions.create!(
      title:
        "Has your child ever had a severe reaction to any medicines, including vaccines?"
    )

  extra_support =
    vaccine.health_questions.create!(
      title: "Does your child need extra support during vaccination sessions?",
      hint: "For example, they’re autistic, or extremely anxious"
    )

  td_ipv_previously =
    vaccine.health_questions.create!(
      title:
        "Has your child had a tetanus, diphtheria and polio vaccination in the last 5 years?",
      hint:
        "Most children will not have had this vaccination since their 4-in-1 pre-school booster"
    )

  bleeding_disorder.update!(next_question: severe_allergies)
  severe_allergies.update!(next_question: severe_reaction)
  severe_reaction.update!(next_question: extra_support)
  extra_support.update!(next_question: td_ipv_previously)
end
