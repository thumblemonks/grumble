require 'pathname'
class Target < ActiveRecord::Base
  VALID_URI_SCHEMES = %w[http https]

  validates_uniqueness_of :uri
  validates_presence_of   :uri
  validate :validate_uri
  has_many :grumbles, :order => 'created_at DESC'

  def self.for_uri(uri)
    uri = normalize_uri(uri)
    find_or_initialize_by_uri(uri)
  end
  
  def to_param
    uri
  end

  def uri=(uri_string)
    normalized = self.class.normalize_uri(uri_string)
    write_attribute(:uri, normalized)
  end
  
private

  def self.normalize_uri(uri_string)
    uri = URI.parse(URI.unescape(uri_string.to_s))
    uri.path = Pathname.new(uri.path).cleanpath.to_s
    uri.to_s
  rescue => e
    return uri_string
  end

  def validate_uri
    parsed_uri = URI.parse(uri.to_s)
    validate_uri_scheme(parsed_uri)
  rescue => e
    errors.add(:uri, "is invalid")
  end

  def validate_uri_scheme(uri)
    unless VALID_URI_SCHEMES.include?(uri.scheme)
      errors.add(:uri, "does not have a valid scheme. Valid schemes are: #{VALID_URI_SCHEMES.join(', ')}")
    end
  end
    
end
