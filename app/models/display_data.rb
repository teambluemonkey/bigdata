class DisplayData
  include Mongoid::Document

  field :some, type: String
  field :data, type: String

  validates_presence_of :some
  validates_uniqueness_of :data

  embedded_in :document

end
