# frozen_string_literal: true

class PatientSessions::BaseController < ApplicationController
  before_action :set_session
  before_action :set_patient
  before_action :set_patient_session
  before_action :set_programme
  before_action :set_breadcrumb_item

  layout "three_quarters"

  private

  def set_session
    @session =
      policy_scope(Session).includes(:location, :programmes).find_by!(
        slug: params.fetch(:session_slug, params[:slug])
      )
  end

  def set_patient
    @patient =
      policy_scope(Patient).includes(parent_relationships: :parent).find(
        params.fetch(:patient_id, params[:id])
      )
  end

  def set_patient_session
    @patient_session =
      PatientSession.find_by!(patient_id: @patient.id, session_id: @session.id)

    # Assigned to already loaded objects
    @patient_session.patient = @patient
    @patient_session.session = @session
  end

  def set_programme
    return unless params.key?(:programme_type) || params.key?(:type)

    @programme =
      @patient_session.programmes.find do |programme|
        programme.type == params[:programme_type] ||
          programme.type == params[:type]
      end

    raise ActiveRecord::RecordNotFound if @programme.nil?
  end

  def set_breadcrumb_item
    return_to = params[:return_to]
    return nil if return_to.blank?

    known_return_to = %w[consent triage register record outcome]
    return unless return_to.in?(known_return_to)

    @breadcrumb_item = {
      text: t(return_to, scope: %i[sessions tabs]),
      href: send(:"session_#{return_to}_path")
    }
  end

  def record_access_log_entry
    @patient.access_log_entries.create!(
      user: current_user,
      controller: "patient_sessions",
      action: access_log_entry_action
    )
  end
end
