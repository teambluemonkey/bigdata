class Document

  include Mongoid::Document

  # automatically generate created_at and updated_at
  include Mongoid::Timestamps

  # attr_accessible :_type, :language, :carrier, :deviceClass, :deviceModelName, :osVersion, :appVersion, :valueType, :description, :key, :value

  before_validation :calculate_display_data

  field :guardian_url, type: String

  field :guardian_data, type: String

  field :guardian_sanitized_data, type: String

  field :semantria_data, type: String

  validates :guardian_url, :guardian_data, :guardian_sanitized_data, :semantria_data, :presence => true

  embeds_one :display_data

private

  def calculate_display_data
    return unless self.display_data.nil?
    # calculate display data....
    self.display_data = DisplayData.new
    self.display_data.some = "woot"
    self.display_data.data = "ya boi"
  end

end