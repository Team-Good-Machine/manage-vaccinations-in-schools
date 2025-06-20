# frozen_string_literal: true

module RequestSessionPersistable
  extend ActiveSupport::Concern

  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveModel::Dirty
  include ActiveRecord::AttributeAssignment

  def initialize(request_session:, current_user:, **attributes)
    @request_session = request_session
    @current_user = current_user

    stored_attributes = @request_session[self.class.request_session_key] || {}

    super(stored_attributes.merge(attributes))

    clear_changes_information

    # When we call `clear_changes_information` we seem to lose time zone
    # information. This happens somewhere in the Rails internals, and
    # it seems to be easier to undo this here.

    self.attributes.each do |key, value|
      self[key] = value.in_time_zone if value.is_a?(Time)
    end
  end

  def assign_attributes(new_attributes)
    super(new_attributes)

    # When assigning multi-parameter dates, time zone information is lost and
    # the date ends up being assigned with the right values but in UTC. This
    # converts the time to local time (Europe/London) but keeping the time
    # components the same. For example: 12:00 UTC -> 12:00 BST.

    attributes.each do |key, value|
      self[key] = Time.zone.local_to_utc(value).in_time_zone if value.is_a?(
        Time
      )
    end
  end

  def save(context: :update)
    reset_unused_fields
    return false if invalid?(context)

    @request_session[
      self.class.request_session_key
    ] = attributes.each_with_object({}) do |(key, value), hash|
      type = self.class.type_for_attribute(key)

      hash[key] = if type.is_a?(ActiveRecord::Type::Serialized)
        type.coder.dump(value)
      else
        value
      end
    end

    true
  end

  def save!(context: :update)
    raise RecordInvalid unless save(context:)
  end

  def update(...)
    assign_attributes(...)
    save(context: :update) # rubocop:disable Rails/SaveBang
  end

  def update!(...)
    assign_attributes(...)
    save!(context: :update)
  end

  def [](attr)
    public_send(attr)
  end

  def []=(attr, value)
    public_send("#{attr}=", value)
  end

  def reset!
    attribute_names.each { |attribute| self[attribute] = nil }
    save!(context: :create)
  end

  class RecordInvalid < StandardError
  end
end
