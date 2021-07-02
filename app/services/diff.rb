# frozen_string_literal: true

require 'net/ldap'

class Diff
  class << self
    # Diff::diff - do a shallow comparison of two hashes to see what attributes have changed
    def diff(old, new, ignored_attrs = [])
      changes = []
      prev_keys = old.keys - ignored_attrs
      new_keys = new.keys - prev_keys - ignored_attrs
      time = Time.now
      prev_keys.each do |old_key|
        old_val = old[old_key]
        new_val = new[old_key]
        changes.push(kind: :updated, timestamp: time, attr: old_key, old: old_val, new: new_val) if old_val != new_val
      end
      new_keys.each do |new_key|
        changes.push(kind: :added, timestamp: time, attr: new_key, old: nil, new: new[new_key])
      end
      changes
    end
  end
end
