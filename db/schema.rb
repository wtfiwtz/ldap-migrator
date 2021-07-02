# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `rails
# db:schema:load`. When creating a new database, `rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2019_11_05_010945) do

  create_table "group_memberships", force: :cascade do |t|
    t.integer "ldap_user_id", null: false
    t.integer "ldap_group_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["ldap_group_id"], name: "index_group_memberships_on_ldap_group_id"
    t.index ["ldap_user_id"], name: "index_group_memberships_on_ldap_user_id"
  end

  create_table "ldap_groups", force: :cascade do |t|
    t.binary "objectguid"
    t.binary "objectsid"
    t.text "dn"
    t.text "objectclass"
    t.string "cn"
    t.text "description"
    t.text "distinguishedname"
    t.integer "instancetype"
    t.datetime "whencreated"
    t.datetime "whenchanged"
    t.datetime "usncreated"
    t.text "member"
    t.datetime "usnchanged"
    t.string "admindisplayname"
    t.text "admindescription"
    t.string "name"
    t.string "samaccountname"
    t.integer "samaccounttype"
    t.integer "grouptype"
    t.text "objectcategory"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["cn"], name: "index_ldap_groups_on_cn"
    t.index ["dn"], name: "index_ldap_groups_on_dn"
    t.index ["objectguid"], name: "index_ldap_groups_on_objectguid", unique: true
  end

  create_table "ldap_users", force: :cascade do |t|
    t.binary "objectguid"
    t.binary "objectsid"
    t.string "dn"
    t.string "cn"
    t.text "objectclass"
    t.string "givenname"
    t.string "sn"
    t.string "mail"
    t.integer "useraccountcontrol"
    t.string "title"
    t.string "c"
    t.string "l"
    t.string "co"
    t.string "department"
    t.string "company"
    t.string "st"
    t.text "description"
    t.string "physicaldeliveryofficename"
    t.string "telephonenumber"
    t.datetime "whencreated"
    t.datetime "whenchanged"
    t.text "info"
    t.text "memberof"
    t.string "homedirectory"
    t.string "profilepath"
    t.string "samaccountname"
    t.datetime "accountexpires"
    t.string "userprincipalname"
    t.string "manager"
    t.string "employeeid"
    t.string "division"
    t.string "departmentnumber"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["cn"], name: "index_ldap_users_on_cn"
    t.index ["dn"], name: "index_ldap_users_on_dn"
    t.index ["objectguid"], name: "index_ldap_users_on_objectguid", unique: true
  end

  create_table "versions", force: :cascade do |t|
    t.string "model_type"
    t.integer "model_id"
    t.text "current"
    t.text "diff"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["model_type", "model_id"], name: "index_versions_on_model_type_and_model_id"
  end

  add_foreign_key "group_memberships", "ldap_groups"
  add_foreign_key "group_memberships", "ldap_users"
end
