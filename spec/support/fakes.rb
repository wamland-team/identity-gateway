# frozen_string_literal: true

# The ActiveSupport::Cache subset the provider relies on, recording each
# entry's lifetime instead of expiring it.
class FakeCache
  attr_reader :entries, :ttls

  def initialize
    @entries = {}
    @ttls = {}
  end

  def read(key)
    entries[key]
  end

  def write(key, value, expires_in:)
    ttls[key] = expires_in
    entries[key] = value
  end

  def delete(key)
    ttls.delete(key)
    entries.delete(key)
  end
end

# A cache whose every call fails, as a store that cannot reach its backend.
class BrokenCache
  %i[read write delete].each do |name|
    define_method(name) { |*, **| raise IOError, 'cache down' }
  end
end

FakeUser = Struct.new(:id)

# The model contract: primary_key, find_by(primary_key => id) and
# from_oauth_provider(hash).
class FakeUsers
  attr_reader :synced

  def initialize
    @records = {}
    @synced = []
  end

  def primary_key
    'id'
  end

  def find_by(conditions)
    @records[conditions.fetch(primary_key)]
  end

  def from_oauth_provider(hash)
    synced << hash
    @records[hash['id']] = FakeUser.new(hash['id'])
  end
end

FakeRequest = Struct.new(:headers)
