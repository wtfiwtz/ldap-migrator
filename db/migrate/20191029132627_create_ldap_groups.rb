class CreateLdapGroups < ActiveRecord::Migration[6.0]
  def change
    create_table :ldap_groups do |t|
      t.binary :objectguid, index: { unique: true }
      t.binary :objectsid
      t.text :dn, index: true
      t.text :objectclass
      t.string :cn, index: true
      t.text :description
      t.text :distinguishedname
      t.integer :instancetype
      t.datetime :whencreated
      t.datetime :whenchanged
      t.datetime :usncreated
      t.text :member
      t.datetime :usnchanged
      t.string :admindisplayname
      t.text :admindescription
      t.string :name
      t.string :samaccountname
      t.integer :samaccounttype
      t.integer :grouptype
      t.text :objectcategory

      t.timestamps
    end
  end
end
