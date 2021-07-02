class CreateLdapUsers < ActiveRecord::Migration[6.0]
  def change
    create_table :ldap_users do |t|
      t.binary :objectguid, index: { unique: true }
      t.binary :objectsid
      t.string :dn, index: true
      t.string :cn, index: true
      t.text :objectclass
      t.string :givenname
      t.string :sn
      t.string :mail
      t.integer :useraccountcontrol
      t.string :title
      t.string :c
      t.string :l
      t.string :co
      t.string :department
      t.string :company
      t.string :st
      t.text :description
      t.string :physicaldeliveryofficename
      t.string :telephonenumber
      t.datetime :whencreated
      t.datetime :whenchanged
      t.text :info
      t.text :memberof
      t.string :homedirectory
      t.string :profilepath
      t.string :samaccountname
      t.datetime :accountexpires
      t.string :userprincipalname
      t.string :manager
      t.string :employeeid
      t.string :division
      t.string :departmentnumber

      t.timestamps
    end
  end
end
