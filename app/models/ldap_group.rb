class LdapGroup < ApplicationRecord
  has_many :group_memberships
  has_many :ldap_users, through: :group_memberships

  serialize :objectclass
  serialize :member

  # TODO: LdapGroup.delete_all fails
  # scope :large_group_ids, lambda do |min_size = 1000|
  #   pluck(:id, :member).reject { |x| x[1].nil? }.select { |x| x[1].count > min_size }.collect { |x| x[0] }
  # end
  # scope :large_groups, lambda do |min_size = 1000|
  #   group_ids = large_group_ids(min_size)
  #   LdapGroup.find(group_ids)
  # end

  scope :resolver_groups, -> { LdapGroup.where("name like '%_SN'") }
end
