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

ActiveRecord::Schema.define(:version => 32) do

  create_table "appointment_event_categories", :force => true do |t|
    t.integer  "appointment_id"
    t.integer  "event_category_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "appointment_waitlists", :force => true do |t|
    t.integer  "appointment_id"
    t.integer  "waitlist_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "appointment_waitlists", ["appointment_id"], :name => "index_appointment_waitlists_on_appointment_id"
  add_index "appointment_waitlists", ["waitlist_id"], :name => "index_appointment_waitlists_on_waitlist_id"

  create_table "appointments", :force => true do |t|
    t.integer  "company_id"
    t.integer  "service_id"
    t.integer  "location_id"
    t.integer  "provider_id"
    t.string   "provider_type"
    t.integer  "customer_id"
    t.integer  "creator_id"
    t.string   "when"
    t.datetime "start_at"
    t.datetime "end_at"
    t.integer  "duration"
    t.string   "time"
    t.integer  "time_start_at"
    t.integer  "time_end_at"
    t.string   "mark_as"
    t.string   "state"
    t.string   "confirmation_code"
    t.string   "uid"
    t.text     "description"
    t.datetime "canceled_at"
    t.boolean  "public",                                     :default => false
    t.string   "name",                        :limit => 100
    t.integer  "popularity",                                 :default => 0
    t.string   "url",                         :limit => 200
    t.integer  "taggings_count",                             :default => 0
    t.string   "source_type",                 :limit => 20
    t.string   "source_id",                   :limit => 50
    t.integer  "recur_parent_id"
    t.string   "recur_rule",                  :limit => 200
    t.datetime "recur_expanded_to"
    t.integer  "recur_remaining_count"
    t.datetime "recur_until"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "capacity",                                   :default => 1
    t.integer  "free_appointment_id"
    t.text     "preferences"
    t.integer  "appointment_waitlists_count",                :default => 0
  end

  add_index "appointments", ["company_id", "start_at", "end_at", "duration", "time_start_at", "time_end_at", "mark_as"], :name => "index_on_openings"
  add_index "appointments", ["company_id"], :name => "index_appointments_on_company_id"
  add_index "appointments", ["creator_id"], :name => "index_appointments_on_creator_id"
  add_index "appointments", ["customer_id"], :name => "index_appointments_on_customer_id"
  add_index "appointments", ["location_id"], :name => "index_appointments_on_location_id"
  add_index "appointments", ["popularity"], :name => "index_appointments_on_popularity"
  add_index "appointments", ["taggings_count"], :name => "index_appointments_on_taggings_count"

  create_table "badges_privileges", :force => true do |t|
    t.string   "name",         :limit => 50
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "lock_version",               :default => 0, :null => false
  end

  add_index "badges_privileges", ["name"], :name => "index_badges_privileges_on_name"

  create_table "badges_role_privileges", :force => true do |t|
    t.integer  "role_id"
    t.integer  "privilege_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "lock_version", :default => 0, :null => false
  end

  add_index "badges_role_privileges", ["privilege_id", "role_id"], :name => "index_badges_role_privileges_on_privilege_id_and_role_id"
  add_index "badges_role_privileges", ["privilege_id"], :name => "index_badges_role_privileges_on_privilege_id"
  add_index "badges_role_privileges", ["role_id"], :name => "index_badges_role_privileges_on_role_id"

  create_table "badges_roles", :force => true do |t|
    t.string   "name",         :limit => 50
    t.string   "string",       :limit => 50
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "lock_version",               :default => 0, :null => false
  end

  add_index "badges_roles", ["name"], :name => "index_badges_roles_on_name"

  create_table "badges_user_roles", :force => true do |t|
    t.integer  "user_id"
    t.integer  "role_id"
    t.string   "authorizable_type", :limit => 30
    t.integer  "authorizable_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "lock_version",                    :default => 0, :null => false
  end

  add_index "badges_user_roles", ["authorizable_type", "authorizable_id"], :name => "index_on_authorizable"
  add_index "badges_user_roles", ["user_id", "role_id", "authorizable_type", "authorizable_id"], :name => "index_on_user_roles_authorizable"

  create_table "bot_stats", :force => true do |t|
    t.string   "name",  :limit => 50
    t.datetime "date"
    t.integer  "count"
  end

  add_index "bot_stats", ["name", "date"], :name => "index_bot_stats_on_name_and_date"
  add_index "bot_stats", ["name"], :name => "index_bot_stats_on_name"

  create_table "capacity_slots", :force => true do |t|
    t.integer  "company_id"
    t.integer  "provider_id"
    t.string   "provider_type"
    t.integer  "location_id"
    t.datetime "start_at"
    t.datetime "end_at"
    t.integer  "duration"
    t.integer  "capacity"
  end

  add_index "capacity_slots", ["capacity"], :name => "index_capacity_slots_on_capacity"
  add_index "capacity_slots", ["company_id"], :name => "index_capacity_slots_on_company_id"
  add_index "capacity_slots", ["duration"], :name => "index_capacity_slots_on_duration"
  add_index "capacity_slots", ["end_at"], :name => "index_capacity_slots_on_end_at"
  add_index "capacity_slots", ["location_id"], :name => "index_capacity_slots_on_location_id"
  add_index "capacity_slots", ["provider_id", "provider_type"], :name => "index_capacity_slots_on_provider_id_and_provider_type"
  add_index "capacity_slots", ["start_at"], :name => "index_capacity_slots_on_start_at"

  create_table "chains", :force => true do |t|
    t.string  "name"
    t.integer "companies_count",                :default => 0
    t.string  "display_name",    :limit => 100
    t.text    "states"
  end

  add_index "chains", ["companies_count"], :name => "index_chains_on_companies_count"
  add_index "chains", ["companies_count"], :name => "index_chains_on_places_count"
  add_index "chains", ["display_name"], :name => "index_chains_on_display_name"
  add_index "chains", ["name"], :name => "index_chains_on_name"

  create_table "cities", :force => true do |t|
    t.string  "name",                :limit => 30
    t.integer "state_id"
    t.decimal "lat",                               :precision => 15, :scale => 10
    t.decimal "lng",                               :precision => 15, :scale => 10
    t.integer "neighborhoods_count",                                               :default => 0
    t.integer "locations_count",                                                   :default => 0
    t.integer "timezone_id"
    t.integer "events_count",                                                      :default => 0
    t.integer "tags_count",                                                        :default => 0
  end

  add_index "cities", ["events_count"], :name => "index_cities_on_events_count"
  add_index "cities", ["locations_count"], :name => "index_cities_on_locations_count"
  add_index "cities", ["neighborhoods_count"], :name => "index_cities_on_neighborhoods_count"
  add_index "cities", ["state_id", "locations_count"], :name => "index_cities_on_state_and_locations"
  add_index "cities", ["state_id", "name"], :name => "index_cities_on_state_and_name"
  add_index "cities", ["state_id"], :name => "index_cities_on_state_id"
  add_index "cities", ["tags_count"], :name => "index_cities_on_tags_count"
  add_index "cities", ["timezone_id"], :name => "index_cities_on_timezone_id"

  create_table "city_zips", :force => true do |t|
    t.integer "city_id"
    t.integer "zip_id"
  end

  add_index "city_zips", ["city_id"], :name => "index_city_zips_on_city_id"
  add_index "city_zips", ["zip_id"], :name => "index_city_zips_on_zip_id"

  create_table "companies", :force => true do |t|
    t.string  "name",                  :limit => 50
    t.integer "locations_count",                      :default => 0
    t.integer "phone_numbers_count",                  :default => 0
    t.integer "chain_id"
    t.integer "taggings_count",                       :default => 0
    t.integer "tag_groups_count",                     :default => 0
    t.string  "time_zone",             :limit => 100
    t.string  "subdomain",             :limit => 100
    t.string  "slogan",                :limit => 100
    t.text    "description"
    t.integer "services_count",                       :default => 0
    t.integer "work_services_count",                  :default => 0
    t.integer "providers_count",                      :default => 0
    t.integer "timezone_id"
    t.text    "preferences"
    t.integer "email_addresses_count",                :default => 0
  end

  add_index "companies", ["chain_id"], :name => "index_companies_on_chain_id"
  add_index "companies", ["name"], :name => "index_places_on_name"
  add_index "companies", ["subdomain"], :name => "index_companies_on_subdomain"
  add_index "companies", ["tag_groups_count"], :name => "index_places_on_tag_groups_count"
  add_index "companies", ["taggings_count"], :name => "index_places_on_taggings_count"
  add_index "companies", ["timezone_id"], :name => "index_companies_on_timezone_id"

  create_table "company_locations", :force => true do |t|
    t.integer "location_id"
    t.integer "company_id"
  end

  add_index "company_locations", ["company_id"], :name => "index_location_places_on_place_id"
  add_index "company_locations", ["location_id"], :name => "index_location_places_on_location_id"

  create_table "company_message_deliveries", :force => true do |t|
    t.integer "company_id"
    t.integer "message_id"
    t.integer "message_recipient_id"
  end

  add_index "company_message_deliveries", ["company_id"], :name => "index_company_message_deliveries_on_company_id"
  add_index "company_message_deliveries", ["message_id"], :name => "index_company_message_deliveries_on_message_id"
  add_index "company_message_deliveries", ["message_recipient_id"], :name => "index_company_message_deliveries_on_message_recipient_id"

  create_table "company_providers", :force => true do |t|
    t.integer  "company_id"
    t.integer  "provider_id"
    t.string   "provider_type", :limit => 50
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "company_providers", ["company_id", "provider_id", "provider_type"], :name => "index_on_companies_and_providers"
  add_index "company_providers", ["provider_id", "provider_type"], :name => "index_on_providers"

  create_table "company_tag_groups", :force => true do |t|
    t.integer "tag_group_id"
    t.integer "company_id"
  end

  add_index "company_tag_groups", ["company_id"], :name => "index_place_tag_groups_on_place_id"
  add_index "company_tag_groups", ["tag_group_id"], :name => "index_place_tag_groups_on_tag_group_id"

  create_table "countries", :force => true do |t|
    t.string  "name",            :limit => 30
    t.string  "code",            :limit => 2
    t.integer "locations_count",               :default => 0
  end

  add_index "countries", ["code"], :name => "index_countries_on_code"
  add_index "countries", ["locations_count"], :name => "index_countries_on_locations_count"

  create_table "delayed_jobs", :force => true do |t|
    t.integer  "priority",   :default => 0
    t.integer  "attempts",   :default => 0
    t.text     "handler"
    t.text     "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "email_addresses", :force => true do |t|
    t.integer  "emailable_id"
    t.string   "emailable_type",        :limit => 50
    t.string   "address",               :limit => 100
    t.string   "email",                 :limit => 100
    t.integer  "priority",                             :default => 1
    t.string   "identifier",            :limit => 150
    t.string   "state",                 :limit => 50
    t.string   "verification_code",     :limit => 50
    t.datetime "verification_sent_at"
    t.datetime "verified_at"
    t.integer  "verification_failures",                :default => 0
  end

  add_index "email_addresses", ["address"], :name => "index_email_addresses_on_address"
  add_index "email_addresses", ["email"], :name => "index_email_addresses_on_email"
  add_index "email_addresses", ["emailable_id", "emailable_type", "priority"], :name => "index_email_on_emailable_and_priority"
  add_index "email_addresses", ["emailable_id", "emailable_type"], :name => "index_email_addresses_on_emailable_id_and_emailable_type"
  add_index "email_addresses", ["emailable_type"], :name => "index_email_addresses_on_emailable_type"

  create_table "event_categories", :force => true do |t|
    t.string  "name",         :limit => 50,                 :null => false
    t.string  "source_type",  :limit => 20,                 :null => false
    t.string  "source_id",    :limit => 50,                 :null => false
    t.integer "popularity",                  :default => 0
    t.string  "tags",         :limit => 150
    t.integer "events_count",                :default => 0
  end

  add_index "event_categories", ["name"], :name => "index_event_categories_on_name"
  add_index "event_categories", ["popularity"], :name => "index_event_categories_on_popularity"
  add_index "event_categories", ["source_id"], :name => "index_event_categories_on_source_id"

  create_table "event_category_mappings", :force => true do |t|
    t.integer  "event_id"
    t.integer  "event_category_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "event_venues", :force => true do |t|
    t.string  "name",                 :limit => 150,                                                :null => false
    t.string  "address"
    t.string  "city",                 :limit => 50,                                                 :null => false
    t.string  "state",                :limit => 50
    t.string  "zip",                  :limit => 10
    t.decimal "lat",                                 :precision => 15, :scale => 10
    t.decimal "lng",                                 :precision => 15, :scale => 10
    t.string  "area_type"
    t.integer "popularity",                                                          :default => 0
    t.string  "source_type",          :limit => 20,                                                 :null => false
    t.string  "source_id",            :limit => 50,                                                 :null => false
    t.integer "confidence",                                                          :default => 0
    t.integer "location_id"
    t.string  "location_source_id",   :limit => 50
    t.string  "location_source_type", :limit => 100
  end

  add_index "event_venues", ["city", "popularity"], :name => "index_event_venues_on_city_and_popularity"
  add_index "event_venues", ["location_id"], :name => "index_event_venues_on_location_id"
  add_index "event_venues", ["popularity"], :name => "index_event_venues_on_popularity"
  add_index "event_venues", ["source_id"], :name => "index_event_venues_on_source_id"

  create_table "events", :force => true do |t|
    t.string   "name",           :limit => 100,                :null => false
    t.integer  "location_id"
    t.integer  "popularity",                    :default => 0
    t.string   "url",            :limit => 200
    t.datetime "start_at"
    t.datetime "end_at"
    t.integer  "taggings_count",                :default => 0
    t.string   "source_type",    :limit => 20,                 :null => false
    t.string   "source_id",      :limit => 50,                 :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "events", ["location_id"], :name => "index_events_on_location_id"
  add_index "events", ["popularity"], :name => "index_events_on_popularity"
  add_index "events", ["taggings_count"], :name => "index_events_on_taggings_count"

  create_table "geo_tag_counts", :force => true do |t|
    t.integer "geo_id"
    t.string  "geo_type",       :limit => 50
    t.integer "tag_id"
    t.integer "taggings_count"
  end

  add_index "geo_tag_counts", ["geo_id", "geo_type"], :name => "index_geo_tag_counts_on_geo_id_and_geo_type"
  add_index "geo_tag_counts", ["taggings_count"], :name => "index_geo_tag_counts_on_taggings_count"

  create_table "invitations", :force => true do |t|
    t.integer  "sender_id"
    t.integer  "recipient_id"
    t.string   "recipient_email"
    t.string   "token"
    t.string   "role"
    t.datetime "sent_at"
    t.integer  "company_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "invitations", ["token"], :name => "index_invitations_on_token"

  create_table "invoice_line_items", :force => true do |t|
    t.integer  "invoice_id"
    t.integer  "chargeable_id"
    t.string   "chargeable_type"
    t.integer  "price_in_cents"
    t.integer  "tax"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "invoices", :force => true do |t|
    t.integer  "invoiceable_id"
    t.string   "invoiceable_type"
    t.integer  "gratuity_in_cents"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "location_neighborhoods", :force => true do |t|
    t.integer "location_id"
    t.integer "neighborhood_id"
  end

  add_index "location_neighborhoods", ["location_id"], :name => "index_ln_on_locations"
  add_index "location_neighborhoods", ["neighborhood_id"], :name => "index_ln_on_neighborhoods"

  create_table "location_neighbors", :force => true do |t|
    t.integer "location_id",                                 :null => false
    t.integer "neighbor_id",                                 :null => false
    t.decimal "distance",    :precision => 15, :scale => 10
  end

  add_index "location_neighbors", ["location_id", "neighbor_id"], :name => "index_location_neighbors_on_location_id_and_neighbor_id", :unique => true
  add_index "location_neighbors", ["location_id"], :name => "index_location_neighbors_on_location_id"
  add_index "location_neighbors", ["neighbor_id"], :name => "index_location_neighbors_on_neighbor_id"

  create_table "location_sources", :force => true do |t|
    t.integer "location_id"
    t.integer "source_id"
    t.string  "source_type"
  end

  add_index "location_sources", ["location_id"], :name => "index_location_sources_on_location_id"
  add_index "location_sources", ["source_id", "source_type"], :name => "index_location_sources_on_source_id_and_source_type"

  create_table "locations", :force => true do |t|
    t.string   "name",                  :limit => 30
    t.string   "street_address"
    t.integer  "city_id"
    t.integer  "state_id"
    t.integer  "zip_id"
    t.integer  "country_id"
    t.integer  "neighborhoods_count",                                                 :default => 0
    t.integer  "phone_numbers_count",                                                 :default => 0
    t.decimal  "lat",                                 :precision => 15, :scale => 10
    t.decimal  "lng",                                 :precision => 15, :scale => 10
    t.integer  "popularity",                                                          :default => 0
    t.integer  "recommendations_count",                                               :default => 0
    t.integer  "events_count",                                                        :default => 0
    t.integer  "status",                                                              :default => 0
    t.integer  "refer_to",                                                            :default => 0
    t.boolean  "delta"
    t.datetime "urban_mapping_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "appointments_count",                                                  :default => 0
    t.integer  "timezone_id"
    t.text     "preferences"
    t.integer  "email_addresses_count",                                               :default => 0
  end

  add_index "locations", ["city_id", "street_address"], :name => "index_locations_on_city_id_and_street_address"
  add_index "locations", ["city_id"], :name => "index_locations_on_city"
  add_index "locations", ["delta"], :name => "index_locations_on_delta"
  add_index "locations", ["events_count"], :name => "index_locations_on_events_count"
  add_index "locations", ["neighborhoods_count"], :name => "index_locations_on_neighborhoods_count"
  add_index "locations", ["popularity"], :name => "index_locations_on_popularity"
  add_index "locations", ["recommendations_count"], :name => "index_locations_on_recommendations_count"
  add_index "locations", ["status"], :name => "index_locations_on_status"
  add_index "locations", ["timezone_id"], :name => "index_locations_on_timezone_id"
  add_index "locations", ["updated_at"], :name => "index_locations_on_updated_at"

  create_table "log_entries", :force => true do |t|
    t.integer  "loggable_id"
    t.string   "loggable_type"
    t.integer  "company_id",    :null => false
    t.integer  "location_id"
    t.integer  "customer_id"
    t.integer  "user_id"
    t.text     "message_body"
    t.integer  "message_id"
    t.integer  "etype"
    t.string   "state"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "logos", :force => true do |t|
    t.string   "image_file_name"
    t.string   "image_content_type"
    t.integer  "image_file_size"
    t.datetime "image_updated_at"
    t.integer  "company_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "logos", ["company_id"], :name => "index_logos_on_company_id"

  create_table "message_recipients", :force => true do |t|
    t.integer  "message_id"
    t.integer  "messagable_id"
    t.string   "messagable_type"
    t.string   "protocol"
    t.string   "state",           :limit => 50
    t.datetime "sent_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "message_recipients", ["message_id"], :name => "index_message_recipients_on_message_id"
  add_index "message_recipients", ["protocol"], :name => "index_message_recipients_on_protocol"
  add_index "message_recipients", ["sent_at"], :name => "index_message_recipients_on_sent_at"
  add_index "message_recipients", ["state"], :name => "index_message_recipients_on_state"

  create_table "message_threads", :force => true do |t|
    t.integer  "message_id"
    t.string   "thread",     :limit => 100
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "message_threads", ["message_id"], :name => "index_message_threads_on_message_id"
  add_index "message_threads", ["thread"], :name => "index_message_threads_on_thread"

  create_table "message_topics", :force => true do |t|
    t.integer  "message_id"
    t.integer  "topic_id"
    t.string   "topic_type"
    t.string   "tag"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "message_topics", ["message_id"], :name => "index_message_topics_on_message_id"
  add_index "message_topics", ["topic_id", "topic_type"], :name => "index_message_topics_on_topic_id_and_topic_type"

  create_table "messages", :force => true do |t|
    t.integer  "sender_id"
    t.string   "subject",     :limit => 200
    t.text     "body"
    t.integer  "priority",                   :default => 0
    t.datetime "send_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "preferences"
  end

  add_index "messages", ["sender_id"], :name => "index_messages_on_sender_id"

  create_table "mobile_carriers", :force => true do |t|
    t.string "name"
    t.string "key"
  end

  add_index "mobile_carriers", ["key"], :name => "index_mobile_carriers_on_key"
  add_index "mobile_carriers", ["name"], :name => "index_mobile_carriers_on_name"

  create_table "neighborhoods", :force => true do |t|
    t.string  "name",            :limit => 50
    t.integer "city_id"
    t.decimal "lat",                           :precision => 15, :scale => 10
    t.decimal "lng",                           :precision => 15, :scale => 10
    t.integer "locations_count",                                               :default => 0
    t.integer "events_count",                                                  :default => 0
    t.integer "tags_count",                                                    :default => 0
  end

  add_index "neighborhoods", ["city_id", "locations_count"], :name => "index_hoods_on_city_and_locations"
  add_index "neighborhoods", ["city_id"], :name => "index_hoods_on_city"
  add_index "neighborhoods", ["events_count"], :name => "index_neighborhoods_on_events_count"
  add_index "neighborhoods", ["locations_count"], :name => "index_hoods_on_locations"
  add_index "neighborhoods", ["tags_count"], :name => "index_neighborhoods_on_tags_count"

  create_table "notes", :force => true do |t|
    t.text     "comment"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "notes_subjects", :force => true do |t|
    t.integer "note_id"
    t.integer "subject_id"
    t.string  "subject_type"
  end

  create_table "payments", :force => true do |t|
    t.integer  "subscription_id"
    t.string   "description"
    t.integer  "amount"
    t.string   "state",           :default => "pending"
    t.boolean  "success"
    t.string   "reference"
    t.string   "message"
    t.string   "action"
    t.text     "params"
    t.boolean  "test"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "phone_numbers", :force => true do |t|
    t.string  "name",          :limit => 20
    t.string  "address",       :limit => 20
    t.integer "callable_id"
    t.string  "callable_type", :limit => 20
    t.integer "priority",                    :default => 1
    t.string  "state",         :limit => 50
  end

  add_index "phone_numbers", ["callable_id", "callable_type"], :name => "index_phone_numbers_on_callable"
  add_index "phone_numbers", ["callable_type", "callable_id", "priority"], :name => "index_phone_on_callable_and_priority"
  add_index "phone_numbers", ["callable_type"], :name => "index_phone_numbers_on_callable_type"

  create_table "plans", :force => true do |t|
    t.string   "name"
    t.boolean  "enabled"
    t.string   "icon"
    t.integer  "cost"
    t.string   "cost_currency"
    t.integer  "max_locations"
    t.integer  "max_providers"
    t.integer  "start_billing_in_time_amount"
    t.string   "start_billing_in_time_unit"
    t.integer  "between_billing_time_amount"
    t.string   "between_billing_time_unit"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "products", :force => true do |t|
    t.integer  "company_id"
    t.string   "name"
    t.integer  "inventory"
    t.integer  "price_in_cents"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "products", ["company_id", "name"], :name => "index_products_on_company_id_and_name"
  add_index "products", ["company_id"], :name => "index_products_on_company_id"

  create_table "promotion_redemptions", :force => true do |t|
    t.integer "promotion_id"
    t.integer "redeemer_id"
    t.string  "redeemer_type", :limit => 50
  end

  add_index "promotion_redemptions", ["promotion_id"], :name => "index_promotion_redemptions_on_promotion_id"
  add_index "promotion_redemptions", ["redeemer_id", "redeemer_type"], :name => "index_promotion_redemptions_on_redeemer_id_and_redeemer_type"

  create_table "promotions", :force => true do |t|
    t.string   "code",              :limit => 50
    t.integer  "uses_allowed",                                     :null => false
    t.integer  "redemptions_count",               :default => 0
    t.string   "description"
    t.float    "discount",                        :default => 0.0
    t.string   "units",             :limit => 50
    t.float    "minimum",                         :default => 0.0
    t.datetime "expires_at"
    t.integer  "owner_id"
    t.string   "owner_type",        :limit => 50
  end

  add_index "promotions", ["code"], :name => "index_promotions_on_code"
  add_index "promotions", ["owner_id", "owner_type"], :name => "index_promotions_on_owner_id_and_owner_type"

  create_table "resources", :force => true do |t|
    t.string  "name"
    t.string  "description"
    t.text    "preferences"
    t.integer "capacity",    :default => 1
  end

  add_index "resources", ["name"], :name => "index_resources_on_name"

  create_table "service_providers", :force => true do |t|
    t.integer  "service_id"
    t.integer  "provider_id"
    t.string   "provider_type"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "service_providers", ["service_id", "provider_id", "provider_type"], :name => "index_on_services_and_providers"

  create_table "services", :force => true do |t|
    t.string   "name"
    t.integer  "duration"
    t.string   "mark_as",               :limit => 50
    t.integer  "price_in_cents"
    t.integer  "providers_count",                     :default => 0
    t.boolean  "allow_custom_duration",               :default => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "preferences"
    t.integer  "company_id"
    t.integer  "capacity",                            :default => 1
  end

  add_index "services", ["mark_as"], :name => "index_services_on_mark_as"

  create_table "states", :force => true do |t|
    t.string  "name",            :limit => 30
    t.string  "code",            :limit => 2
    t.integer "country_id"
    t.decimal "lat",                           :precision => 15, :scale => 10
    t.decimal "lng",                           :precision => 15, :scale => 10
    t.integer "cities_count",                                                  :default => 0
    t.integer "zips_count",                                                    :default => 0
    t.integer "locations_count",                                               :default => 0
    t.integer "events",                                                        :default => 0
  end

  add_index "states", ["country_id", "code"], :name => "index_states_on_country_id_and_code"
  add_index "states", ["country_id", "locations_count"], :name => "index_states_on_country_id_and_locations_count"
  add_index "states", ["country_id", "name"], :name => "index_states_on_country_id_and_name"
  add_index "states", ["country_id"], :name => "index_states_on_country_id"

  create_table "subscriptions", :force => true do |t|
    t.integer  "user_id"
    t.integer  "company_id"
    t.integer  "plan_id"
    t.datetime "start_billing_at"
    t.datetime "last_billing_at"
    t.datetime "next_billing_at"
    t.integer  "paid_count",           :default => 0
    t.integer  "billing_errors_count", :default => 0
    t.string   "vault_id"
    t.string   "state",                :default => "initialized"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "subscriptions", ["company_id"], :name => "index_subscriptions_on_company_id"

  create_table "tag_groups", :force => true do |t|
    t.string   "name",                              :null => false
    t.text     "tags"
    t.text     "recent_add_tags"
    t.text     "recent_remove_tags"
    t.integer  "companies_count",    :default => 0
    t.datetime "applied_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "tag_groups", ["companies_count"], :name => "index_tag_groups_on_places_count"
  add_index "tag_groups", ["name"], :name => "index_tag_groups_on_name"

  create_table "taggings", :force => true do |t|
    t.integer  "tag_id"
    t.integer  "taggable_id"
    t.integer  "tagger_id"
    t.string   "tagger_type"
    t.string   "taggable_type", :limit => 20
    t.string   "context",       :limit => 20
    t.datetime "created_at"
  end

  add_index "taggings", ["tag_id"], :name => "index_taggings_on_tag_id"
  add_index "taggings", ["taggable_id", "taggable_type", "context"], :name => "index_taggings_on_taggable_id_and_taggable_type_and_context"
  add_index "taggings", ["taggable_id", "taggable_type"], :name => "index_taggings_on_taggable_id_and_taggable_type"
  add_index "taggings", ["taggable_type"], :name => "index_taggings_on_taggable_type"

  create_table "tags", :force => true do |t|
    t.string  "name",           :limit => 30
    t.integer "taggings_count",               :default => 0
  end

  add_index "tags", ["name"], :name => "index_tags_on_name"

  create_table "timezones", :force => true do |t|
    t.string  "name",                 :limit => 100, :null => false
    t.integer "utc_offset",                          :null => false
    t.integer "utc_dst_offset",                      :null => false
    t.string  "rails_time_zone_name", :limit => 100
  end

  create_table "users", :force => true do |t|
    t.string   "name",                      :limit => 100, :default => ""
    t.string   "crypted_password",          :limit => 40
    t.string   "cal_dav_token",             :limit => 150
    t.string   "salt",                      :limit => 40
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "remember_token",            :limit => 40
    t.datetime "remember_token_expires_at"
    t.string   "activation_code",           :limit => 40
    t.datetime "activated_at"
    t.string   "state",                                    :default => "passive"
    t.datetime "deleted_at"
    t.text     "preferences"
    t.integer  "phone_numbers_count",                      :default => 0
    t.integer  "email_addresses_count",                    :default => 0
    t.integer  "rpx",                                      :default => 0
    t.integer  "capacity",                                 :default => 1
  end

  add_index "users", ["name"], :name => "index_users_on_name"

  create_table "waitlist_time_ranges", :force => true do |t|
    t.integer  "waitlist_id"
    t.datetime "start_date"
    t.datetime "end_date"
    t.integer  "start_time"
    t.integer  "end_time"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "waitlist_time_ranges", ["waitlist_id"], :name => "index_waitlist_time_ranges_on_waitlist_id"

  create_table "waitlists", :force => true do |t|
    t.integer  "company_id"
    t.integer  "service_id"
    t.integer  "location_id"
    t.integer  "provider_id"
    t.string   "provider_type"
    t.integer  "customer_id"
    t.integer  "creator_id"
    t.integer  "appointment_waitlists_count", :default => 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "waitlists", ["company_id"], :name => "index_waitlists_on_company_id"
  add_index "waitlists", ["creator_id"], :name => "index_waitlists_on_creator_id"
  add_index "waitlists", ["customer_id"], :name => "index_waitlists_on_customer_id"
  add_index "waitlists", ["location_id"], :name => "index_waitlists_on_location_id"
  add_index "waitlists", ["provider_id", "provider_type"], :name => "index_waitlists_on_provider_id_and_provider_type"
  add_index "waitlists", ["service_id"], :name => "index_waitlists_on_service_id"

  create_table "zips", :force => true do |t|
    t.string  "name",            :limit => 10
    t.integer "state_id"
    t.decimal "lat",                           :precision => 15, :scale => 10
    t.decimal "lng",                           :precision => 15, :scale => 10
    t.integer "locations_count",                                               :default => 0
    t.integer "timezone_id"
    t.integer "events_count",                                                  :default => 0
    t.integer "tags_count",                                                    :default => 0
  end

  add_index "zips", ["events_count"], :name => "index_zips_on_events_count"
  add_index "zips", ["state_id", "locations_count"], :name => "index_zips_on_state_id_and_locations_count"
  add_index "zips", ["state_id"], :name => "index_zips_on_state_id"
  add_index "zips", ["tags_count"], :name => "index_zips_on_tags_count"
  add_index "zips", ["timezone_id"], :name => "index_zips_on_timezone_id"

end
