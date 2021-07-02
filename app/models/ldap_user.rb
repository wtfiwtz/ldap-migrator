class LdapUser < ApplicationRecord
  has_many :group_memberships
  has_many :ldap_groups, through: :group_memberships
  has_many :versions, as: :model

  serialize :objectclass
  serialize :memberof

  scope :password_not_expiring, ->  { where('useraccountcontrol & 0x00010000 == 0x00010000') }
  scope :password_expired, ->       { where('useraccountcontrol & 0x00800000 == 0x00800000') }
  scope :locked_out, ->             { where('useraccountcontrol & 0x00000010 == 0x00000010') }
end
