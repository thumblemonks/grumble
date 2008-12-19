# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of Active Record to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20081219221139) do

  create_table "grumblers", :force => true do |t|
    t.string   "name",                     :null => false
    t.string   "uuid",       :limit => 36, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "grumblers", ["uuid"], :name => "index_grumblers_on_uuid", :unique => true

  create_table "grumbles", :force => true do |t|
    t.integer  "target_id"
    t.integer  "grumbler_id"
    t.text     "subject",                          :null => false
    t.text     "body",                             :null => false
    t.string   "anon_grumbler_name"
    t.string   "uuid",               :limit => 36, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "grumbles", ["uuid"], :name => "index_grumbles_on_uuid", :unique => true

  create_table "targets", :force => true do |t|
    t.text     "uri",        :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
