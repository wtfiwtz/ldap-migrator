class GroupMembership < ApplicationRecord
  belongs_to :ldap_user
  belongs_to :ldap_group
end
