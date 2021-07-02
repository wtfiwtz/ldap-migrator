class CreateGroupMemberships < ActiveRecord::Migration[6.0]
  def change
    create_table :group_memberships do |t|
      t.references :ldap_user, null: false, foreign_key: true
      t.references :ldap_group, null: false, foreign_key: true

      t.timestamps
    end
  end
end
