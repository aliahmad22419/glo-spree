# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.2].define(version: 2024_10_09_074447) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "action_mailbox_inbound_emails", force: :cascade do |t|
    t.integer "status", default: 0, null: false
    t.string "message_id", null: false
    t.string "message_checksum", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["message_id", "message_checksum"], name: "index_action_mailbox_inbound_emails_uniqueness", unique: true
  end

  create_table "action_text_rich_texts", force: :cascade do |t|
    t.string "name", null: false
    t.text "body"
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["record_type", "record_id", "name"], name: "index_action_text_rich_texts_uniqueness", unique: true
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", precision: nil, null: false
    t.text "alt"
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.bigint "byte_size", null: false
    t.string "checksum", null: false
    t.datetime "created_at", precision: nil, null: false
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "apple_passbooks", force: :cascade do |t|
    t.json "pass"
    t.string "p12_password"
    t.bigint "store_id", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "barcode_format"
    t.string "stripe_image"
    t.text "preferences"
    t.index ["store_id"], name: "index_apple_passbooks_on_store_id"
  end

  create_table "batch_schedules", force: :cascade do |t|
    t.date "start_date"
    t.date "end_date"
    t.integer "interval", default: 0
    t.integer "step_count", default: 0
    t.text "week_days", default: [], array: true
    t.text "month_dates", default: [], array: true
    t.string "time_zone", default: "UTC", null: false
    t.string "schedulable_type", null: false
    t.bigint "schedulable_id", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["schedulable_type", "schedulable_id"], name: "index_batch_schedules_on_schedulable_type_and_schedulable_id"
  end

  create_table "email_changes", force: :cascade do |t|
    t.integer "user_id"
    t.string "previous_email"
    t.string "next_email"
    t.text "note"
    t.string "updatable_type"
    t.bigint "updatable_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["updatable_type", "updatable_id"], name: "index_email_changes_on_updatable_type_and_updatable_id"
  end

  create_table "friendly_id_slugs", id: :serial, force: :cascade do |t|
    t.string "slug", null: false
    t.bigint "sluggable_id", null: false
    t.string "sluggable_type", limit: 50
    t.string "scope"
    t.datetime "created_at", precision: nil
    t.datetime "deleted_at", precision: nil
    t.string "locale"
    t.index ["deleted_at"], name: "index_friendly_id_slugs_on_deleted_at"
    t.index ["locale"], name: "index_friendly_id_slugs_on_locale"
    t.index ["slug", "sluggable_type", "locale"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type_and_locale"
    t.index ["slug", "sluggable_type", "scope", "locale"], name: "index_friendly_id_slugs_unique", unique: true
    t.index ["sluggable_id"], name: "index_friendly_id_slugs_on_sluggable_id"
    t.index ["sluggable_type"], name: "index_friendly_id_slugs_on_sluggable_type"
  end

  create_table "history_logs", force: :cascade do |t|
    t.string "kind"
    t.text "history_notes"
    t.string "creator_email"
    t.string "platform"
    t.json "meta"
    t.string "loggable_type"
    t.bigint "loggable_id"
    t.bigint "creator_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["creator_id"], name: "index_history_logs_on_creator_id"
    t.index ["loggable_type", "loggable_id"], name: "index_history_logs_on_loggable"
  end

  create_table "mailchimp_settings", id: :serial, force: :cascade do |t|
    t.string "mailchimp_api_key"
    t.string "mailchimp_store_id"
    t.string "mailchimp_list_id"
    t.string "mailchimp_store_name"
    t.string "cart_url"
    t.string "mailchimp_account_name"
    t.string "state", default: "inactive"
    t.string "mailchimp_store_email"
    t.integer "store_id"
    t.string "mailchimp_url"
    t.bigint "client_id"
    t.index ["mailchimp_store_name", "client_id"], name: "index_mailchimp_settings_on_mailchimp_store_name_and_client_id", unique: true
  end

  create_table "menu_item_users", force: :cascade do |t|
    t.integer "menu_item_id"
    t.integer "user_id"
    t.integer "parent_id"
    t.boolean "visible"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.boolean "permissible", default: true
    t.index ["menu_item_id", "user_id"], name: "index_menu_item_users_on_menu_item_id_and_user_id", unique: true
  end

  create_table "menu_items", force: :cascade do |t|
    t.string "name"
    t.text "url"
    t.string "img_url"
    t.boolean "namespace", default: false
    t.text "menu_permission_roles", default: [], array: true
    t.decimal "priority", precision: 8, scale: 2, default: "0.0", null: false
    t.boolean "visible", default: false
    t.integer "parent_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.boolean "permissible", default: true
    t.string "controller"
    t.text "actions", default: [], array: true
    t.index ["url", "name"], name: "index_menu_items_on_url_and_name", unique: true
  end

  create_table "order_error_logs", force: :cascade do |t|
    t.integer "error_type", null: false
    t.integer "status", default: 0, null: false
    t.integer "attempts", default: 0, null: false
    t.string "message", null: false
    t.json "meta"
    t.bigint "order_id"
    t.bigint "line_item_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["line_item_id"], name: "index_order_error_logs_on_line_item_id"
    t.index ["order_id"], name: "index_order_error_logs_on_order_id"
  end

  create_table "product_batches", force: :cascade do |t|
    t.string "product_name"
    t.integer "product_quantity"
    t.jsonb "variants", default: []
    t.integer "status", default: 0
    t.decimal "product_price", precision: 10, scale: 2, default: "0.0"
    t.text "option_type_ids", default: [], array: true
    t.bigint "product_id"
    t.datetime "deleted_at", precision: nil
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["product_id"], name: "index_product_batches_on_product_id"
  end

  create_table "scheduled_reports", force: :cascade do |t|
    t.string "report_type"
    t.integer "scheduled_on", default: 0
    t.string "password"
    t.text "store_ids", default: [], array: true
    t.text "ts_store_ids", default: [], array: true
    t.string "reportable_type"
    t.bigint "reportable_id"
    t.text "preferences"
    t.text "report_link"
    t.datetime "report_link_updated_at", precision: nil
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.date "start_date"
    t.date "end_date"
    t.index ["reportable_type", "reportable_id"], name: "index_scheduled_reports_on_reportable_type_and_reportable_id"
  end

  create_table "sftp_files", force: :cascade do |t|
    t.string "name"
    t.string "object_key"
    t.string "s3_file_url"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "sftp_users", force: :cascade do |t|
    t.string "email"
    t.string "password"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "spree_acm_cnames", force: :cascade do |t|
    t.string "name"
    t.string "c_type"
    t.string "value"
    t.string "domain_name"
    t.string "validation_method"
    t.string "validation_status"
    t.integer "store_id"
  end

  create_table "spree_addresses", id: :serial, force: :cascade do |t|
    t.string "firstname"
    t.string "lastname"
    t.string "address1"
    t.string "address2"
    t.string "city"
    t.string "zipcode"
    t.string "phone"
    t.string "state_name"
    t.string "alternative_phone"
    t.string "company"
    t.bigint "state_id"
    t.bigint "country_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "email"
    t.string "braintree_id"
    t.bigint "user_id"
    t.datetime "deleted_at", precision: nil
    t.string "apartment_no"
    t.string "estate_name"
    t.string "region"
    t.string "district"
    t.integer "magento_id"
    t.integer "store_id"
    t.string "phone_code"
    t.float "latitude"
    t.float "longitude"
    t.boolean "is_v3_flow_address", default: false
    t.string "label"
    t.jsonb "public_metadata"
    t.jsonb "private_metadata"
    t.string "credit_card_descriptor"
    t.index ["country_id"], name: "index_spree_addresses_on_country_id"
    t.index ["deleted_at"], name: "index_spree_addresses_on_deleted_at"
    t.index ["firstname"], name: "index_addresses_on_firstname"
    t.index ["lastname"], name: "index_addresses_on_lastname"
    t.index ["state_id"], name: "index_spree_addresses_on_state_id"
    t.index ["user_id"], name: "index_spree_addresses_on_user_id"
  end

  create_table "spree_adjustments", id: :serial, force: :cascade do |t|
    t.string "source_type"
    t.bigint "source_id"
    t.string "adjustable_type"
    t.bigint "adjustable_id"
    t.decimal "amount", precision: 16, scale: 2
    t.string "label"
    t.boolean "mandatory"
    t.boolean "eligible", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "state"
    t.bigint "order_id", null: false
    t.boolean "included", default: false
    t.index ["adjustable_id", "adjustable_type"], name: "index_spree_adjustments_on_adjustable_id_and_adjustable_type"
    t.index ["eligible"], name: "index_spree_adjustments_on_eligible"
    t.index ["order_id"], name: "index_spree_adjustments_on_order_id"
    t.index ["source_id", "source_type"], name: "index_spree_adjustments_on_source_id_and_source_type"
  end

  create_table "spree_adyen_accounts", force: :cascade do |t|
    t.string "account_code"
    t.string "account_holder_code"
    t.bigint "vendor_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["vendor_id"], name: "index_spree_adyen_accounts_on_vendor_id"
  end

  create_table "spree_adyen_checkouts", force: :cascade do |t|
    t.string "number"
    t.string "month"
    t.string "year"
    t.string "cc_type"
    t.string "name"
    t.string "gateway_payment_profile_id"
    t.string "gateway_customer_profile_id"
    t.string "payment_method_id"
    t.string "user_id"
    t.string "verification_value"
    t.string "status"
    t.string "psp_reference"
    t.json "three_ds_action"
    t.json "card_details"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "spree_answers", force: :cascade do |t|
    t.string "title"
    t.integer "question_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "spree_assets", id: :serial, force: :cascade do |t|
    t.string "viewable_type"
    t.bigint "viewable_id"
    t.integer "attachment_width"
    t.integer "attachment_height"
    t.integer "attachment_file_size"
    t.integer "position"
    t.string "attachment_content_type"
    t.string "attachment_file_name"
    t.string "type", limit: 75
    t.datetime "attachment_updated_at", precision: nil
    t.text "alt"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.boolean "base_image", default: false
    t.boolean "thumbnail", default: false
    t.boolean "small_image", default: false
    t.integer "sort_order", default: 1
    t.integer "sort_order_info_product", default: 1
    t.jsonb "public_metadata"
    t.jsonb "private_metadata"
    t.index ["position"], name: "index_spree_assets_on_position"
    t.index ["viewable_id"], name: "index_assets_on_viewable_id"
    t.index ["viewable_type", "type"], name: "index_assets_on_viewable_type_and_type"
  end

  create_table "spree_aws_files", force: :cascade do |t|
    t.string "name"
    t.string "url"
    t.string "comment"
    t.boolean "active", default: false
    t.string "file_type", default: "text"
    t.bigint "client_id"
    t.bigint "created_by_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["client_id"], name: "index_spree_aws_files_on_client_id"
    t.index ["created_by_id"], name: "index_spree_aws_files_on_created_by_id"
  end

  create_table "spree_bookkeeping_documents", id: :serial, force: :cascade do |t|
    t.string "printable_type"
    t.integer "printable_id"
    t.string "template"
    t.string "number"
    t.string "firstname"
    t.string "lastname"
    t.string "email"
    t.decimal "total", precision: 16, scale: 2
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "vendor_id"
    t.boolean "old_invoice"
    t.integer "shipment_id"
  end

  create_table "spree_braintree_checkouts", id: :serial, force: :cascade do |t|
    t.string "transaction_id"
    t.string "state"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "paypal_email"
    t.string "advanced_fraud_data"
    t.string "risk_id"
    t.string "risk_decision"
    t.string "braintree_last_digits", limit: 4
    t.string "braintree_card_type"
    t.boolean "admin_payment"
    t.index ["state"], name: "index_spree_braintree_checkouts_on_state"
    t.index ["transaction_id"], name: "index_spree_braintree_checkouts_on_transaction_id"
  end

  create_table "spree_bulk_orders", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "client_id", null: false
    t.string "state", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["client_id"], name: "index_spree_bulk_orders_on_client_id"
    t.index ["user_id"], name: "index_spree_bulk_orders_on_user_id"
  end

  create_table "spree_calculated_prices", force: :cascade do |t|
    t.string "to_currency"
    t.bigint "calculated_price_id"
    t.string "calculated_price_type"
    t.jsonb "calculated_value", default: {}, null: false
    t.jsonb "meta", default: {}, null: false
    t.index ["calculated_price_id"], name: "index_spree_calculated_prices_on_calculated_price_id"
    t.index ["calculated_price_type"], name: "index_spree_calculated_prices_on_calculated_price_type"
  end

  create_table "spree_calculators", id: :serial, force: :cascade do |t|
    t.string "type"
    t.string "calculable_type"
    t.bigint "calculable_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "preferences"
    t.datetime "deleted_at", precision: nil
    t.index ["calculable_id", "calculable_type"], name: "index_spree_calculators_on_calculable_id_and_calculable_type"
    t.index ["deleted_at"], name: "index_spree_calculators_on_deleted_at"
    t.index ["id", "type"], name: "index_spree_calculators_on_id_and_type"
  end

  create_table "spree_checks", force: :cascade do |t|
    t.bigint "payment_method_id"
    t.bigint "user_id"
    t.string "account_holder_name"
    t.string "account_holder_type"
    t.string "routing_number"
    t.string "account_number"
    t.string "account_type", default: "checking"
    t.string "status"
    t.string "last_digits"
    t.string "gateway_customer_profile_id"
    t.string "gateway_payment_profile_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.datetime "deleted_at", precision: nil
    t.index ["payment_method_id"], name: "index_spree_checks_on_payment_method_id"
    t.index ["user_id"], name: "index_spree_checks_on_user_id"
  end

  create_table "spree_clients", force: :cascade do |t|
    t.string "name"
    t.string "email"
    t.text "supported_currencies", default: [], array: true
    t.string "stipe_connected_account_id"
    t.string "logo_file_name"
    t.string "app_fee_type", default: "percentage"
    t.integer "app_fee", default: 0
    t.text "product_validations", default: [], array: true
    t.integer "number_of_images", default: 0
    t.boolean "zone_based_stores", default: false
    t.boolean "already_selling", default: false
    t.decimal "current_revenue"
    t.string "type_of_industry"
    t.string "selling_platform"
    t.integer "client_address_id"
    t.boolean "multi_vendor_store", default: false
    t.boolean "new_layout", default: false
    t.boolean "enable_mov", default: false
    t.boolean "allow_brand_follow", default: false
    t.boolean "auto_approve_products", default: false
    t.string "reporting_currency", default: "USD"
    t.string "business_name"
    t.string "skill_level"
    t.string "product_type"
    t.boolean "job_completed", default: true
    t.boolean "allow_sub_folder_urls", default: false
    t.string "ts_email"
    t.string "ts_password"
    t.string "ts_url"
    t.string "sales_report_password"
    t.string "from_phone_number", default: ""
    t.string "customer_support_email"
    t.boolean "show_gift_card_number", default: true
    t.boolean "show_all_gift_card_digits", default: true
    t.string "timezone", default: "Europe/London"
    t.string "reporting_from_email_address"
    t.text "preferences"
    t.boolean "act_as_merchant", default: false
  end

  create_table "spree_clients_service_login", force: :cascade do |t|
    t.bigint "service_login_sub_admin_id", null: false
    t.bigint "client_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["client_id"], name: "index_spree_clients_service_login_on_client_id"
    t.index ["service_login_sub_admin_id"], name: "index_spree_clients_service_login_on_service_login_sub_admin_id"
  end

  create_table "spree_cms_pages", force: :cascade do |t|
    t.string "title", null: false
    t.string "meta_title"
    t.text "content"
    t.text "meta_description"
    t.boolean "visible", default: true
    t.string "slug"
    t.string "type"
    t.string "locale"
    t.datetime "deleted_at", precision: nil
    t.bigint "store_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["deleted_at"], name: "index_spree_cms_pages_on_deleted_at"
    t.index ["slug", "store_id", "deleted_at"], name: "index_spree_cms_pages_on_slug_and_store_id_and_deleted_at", unique: true
    t.index ["store_id", "locale", "type"], name: "index_spree_cms_pages_on_store_id_and_locale_and_type"
    t.index ["store_id"], name: "index_spree_cms_pages_on_store_id"
    t.index ["title", "type", "store_id"], name: "index_spree_cms_pages_on_title_and_type_and_store_id"
    t.index ["visible"], name: "index_spree_cms_pages_on_visible"
  end

  create_table "spree_cms_sections", force: :cascade do |t|
    t.string "name", null: false
    t.text "content"
    t.text "settings"
    t.string "fit"
    t.string "destination"
    t.string "type"
    t.integer "position"
    t.string "linked_resource_type"
    t.bigint "linked_resource_id"
    t.bigint "cms_page_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["cms_page_id"], name: "index_spree_cms_sections_on_cms_page_id"
    t.index ["linked_resource_type", "linked_resource_id"], name: "index_spree_cms_sections_on_linked_resource"
    t.index ["position"], name: "index_spree_cms_sections_on_position"
    t.index ["type"], name: "index_spree_cms_sections_on_type"
  end

  create_table "spree_countries", id: :serial, force: :cascade do |t|
    t.string "iso_name"
    t.string "iso", null: false
    t.string "iso3", null: false
    t.string "name"
    t.integer "numcode"
    t.boolean "states_required", default: false
    t.datetime "updated_at", precision: nil
    t.boolean "zipcode_required", default: true
    t.boolean "region_required", default: false
    t.bigint "client_id"
    t.datetime "created_at", precision: nil
    t.index ["client_id"], name: "index_spree_countries_on_client_id"
    t.index ["iso"], name: "index_spree_countries_on_iso", unique: true
    t.index ["iso3"], name: "index_spree_countries_on_iso3", unique: true
    t.index ["iso_name", "client_id"], name: "index_spree_countries_on_iso_name_and_client_id", unique: true
    t.index ["name", "client_id"], name: "index_spree_countries_on_name_and_client_id", unique: true
  end

  create_table "spree_countries_stores", force: :cascade do |t|
    t.bigint "store_id"
    t.bigint "country_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["country_id"], name: "index_spree_countries_stores_on_country_id"
    t.index ["store_id"], name: "index_spree_countries_stores_on_store_id"
  end

  create_table "spree_credit_cards", id: :serial, force: :cascade do |t|
    t.string "month"
    t.string "year"
    t.string "cc_type"
    t.string "last_digits"
    t.bigint "address_id"
    t.string "gateway_customer_profile_id"
    t.string "gateway_payment_profile_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "name"
    t.bigint "user_id"
    t.bigint "payment_method_id"
    t.boolean "default", default: false, null: false
    t.datetime "deleted_at", precision: nil
    t.jsonb "public_metadata"
    t.jsonb "private_metadata"
    t.index ["address_id"], name: "index_spree_credit_cards_on_address_id"
    t.index ["deleted_at"], name: "index_spree_credit_cards_on_deleted_at"
    t.index ["payment_method_id"], name: "index_spree_credit_cards_on_payment_method_id"
    t.index ["user_id"], name: "index_spree_credit_cards_on_user_id"
  end

  create_table "spree_crypto_wallets", force: :cascade do |t|
    t.decimal "crypto_amount", precision: 16, scale: 2
    t.string "crypto_currency"
    t.string "customer_id"
    t.string "source_name"
    t.string "track_id"
    t.string "status"
    t.integer "payment_method_id"
    t.integer "user_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["payment_method_id"], name: "index_spree_crypto_wallets_on_payment_method_id"
    t.index ["user_id"], name: "index_spree_crypto_wallets_on_user_id"
  end

  create_table "spree_currencies", force: :cascade do |t|
    t.string "name"
    t.decimal "value", precision: 16, scale: 2
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "vendor_id"
    t.bigint "client_id"
    t.index ["client_id"], name: "index_spree_currencies_on_client_id"
  end

  create_table "spree_customer_returns", id: :serial, force: :cascade do |t|
    t.string "number"
    t.bigint "stock_location_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "client_id"
    t.bigint "store_id"
    t.jsonb "public_metadata"
    t.jsonb "private_metadata"
    t.index ["client_id"], name: "index_spree_customer_returns_on_client_id"
    t.index ["number"], name: "index_spree_customer_returns_on_number", unique: true
    t.index ["stock_location_id"], name: "index_spree_customer_returns_on_stock_location_id"
    t.index ["store_id"], name: "index_spree_customer_returns_on_store_id"
  end

  create_table "spree_customization_options", force: :cascade do |t|
    t.string "label"
    t.string "value"
    t.string "sku"
    t.decimal "price", precision: 16, scale: 2, default: "0.0"
    t.integer "customization_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "magento_id"
    t.integer "max_characters"
    t.string "color_code"
  end

  create_table "spree_customizations", force: :cascade do |t|
    t.string "label"
    t.string "field_type"
    t.decimal "price", precision: 16, scale: 2, default: "0.0"
    t.integer "product_id"
    t.boolean "is_required"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "order"
    t.integer "magento_id"
    t.text "store_ids", default: [], array: true
    t.integer "max_characters"
    t.boolean "show_price", default: false
  end

  create_table "spree_data_feeds", force: :cascade do |t|
    t.bigint "store_id"
    t.string "name"
    t.string "type"
    t.string "slug"
    t.boolean "active", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["store_id", "slug", "type"], name: "index_spree_data_feeds_on_store_id_and_slug_and_type"
    t.index ["store_id"], name: "index_spree_data_feeds_on_store_id"
  end

  create_table "spree_digital_links", force: :cascade do |t|
    t.bigint "digital_id"
    t.bigint "line_item_id"
    t.string "token"
    t.integer "access_counter"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["digital_id"], name: "index_spree_digital_links_on_digital_id"
    t.index ["line_item_id"], name: "index_spree_digital_links_on_line_item_id"
    t.index ["token"], name: "index_spree_digital_links_on_token", unique: true
  end

  create_table "spree_digitals", force: :cascade do |t|
    t.bigint "variant_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["variant_id"], name: "index_spree_digitals_on_variant_id"
  end

  create_table "spree_domains", force: :cascade do |t|
    t.string "name"
    t.integer "client_id"
  end

  create_table "spree_email_notification_configurations", force: :cascade do |t|
    t.text "preferences"
    t.bigint "store_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["store_id"], name: "index_spree_email_notification_configurations_on_store_id"
  end

  create_table "spree_email_templates", force: :cascade do |t|
    t.string "name"
    t.text "subject"
    t.text "email_text"
    t.text "html"
    t.integer "store_id"
    t.string "email_type"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "client_id"
  end

  create_table "spree_embed_widgets", force: :cascade do |t|
    t.string "site_domain"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.bigint "client_id"
    t.index ["client_id"], name: "index_spree_embed_widgets_on_client_id"
  end

  create_table "spree_exchange_rates", force: :cascade do |t|
    t.string "name"
    t.decimal "value", precision: 16, scale: 8
    t.integer "currency_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "spree_feedback_reviews", id: :serial, force: :cascade do |t|
    t.bigint "user_id"
    t.bigint "review_id", null: false
    t.integer "rating", default: 0
    t.text "comment"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "locale", default: "en"
    t.index ["review_id"], name: "index_spree_feedback_reviews_on_review_id"
    t.index ["user_id"], name: "index_spree_feedback_reviews_on_user_id"
  end

  create_table "spree_follows", force: :cascade do |t|
    t.integer "follower_id"
    t.integer "followee_id"
    t.string "name"
    t.string "email"
    t.text "details"
    t.string "status", default: "pending"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "website"
    t.string "instagram"
    t.string "country_name"
  end

  create_table "spree_front_desk_credentials", force: :cascade do |t|
    t.string "tsgifts_email"
    t.string "tsgifts_password"
    t.integer "user_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "tsgifts_url"
    t.string "tsdefault_currency"
  end

  create_table "spree_fulfilment_infos", force: :cascade do |t|
    t.string "gift_card_number"
    t.string "serial_number"
    t.string "currency"
    t.decimal "customer_shippment_paid", precision: 10, scale: 2
    t.datetime "processed_date", precision: nil
    t.string "postage_currency"
    t.decimal "postage_fee", precision: 10, scale: 2
    t.string "receipt_reference"
    t.string "courier_company"
    t.string "tracking_number"
    t.string "comment"
    t.boolean "accurate_submition", default: false
    t.bigint "shipment_id"
    t.bigint "user_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.decimal "amount", precision: 10, scale: 2
    t.integer "quantity"
    t.json "replacement_info"
    t.integer "info_type", default: 0
    t.integer "original_id"
    t.string "each_card_value"
    t.bigint "replacement_id"
    t.integer "state", default: 0
    t.index ["replacement_id"], name: "index_spree_fulfilment_infos_on_replacement_id"
  end

  create_table "spree_fulfilment_teams", force: :cascade do |t|
    t.string "name"
    t.string "code"
    t.bigint "creator_id"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
  end

  create_table "spree_fulfilment_teams_users", force: :cascade do |t|
    t.bigint "fulfilment_team_id"
    t.bigint "user_id"
  end

  create_table "spree_fulfilment_teams_zones", force: :cascade do |t|
    t.bigint "fulfilment_team_id"
    t.bigint "zone_id"
  end

  create_table "spree_galleries", force: :cascade do |t|
    t.integer "attachment_id"
    t.integer "client_id"
    t.datetime "created_at", precision: nil, default: -> { "now()" }, null: false
    t.datetime "updated_at", precision: nil, default: -> { "now()" }, null: false
  end

  create_table "spree_gateways", id: :serial, force: :cascade do |t|
    t.string "type"
    t.string "name"
    t.text "description"
    t.boolean "active", default: true
    t.string "environment", default: "development"
    t.string "server", default: "test"
    t.boolean "test_mode", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "preferences"
    t.index ["active"], name: "index_spree_gateways_on_active"
    t.index ["test_mode"], name: "index_spree_gateways_on_test_mode"
  end

  create_table "spree_gift_card_pdfs", force: :cascade do |t|
    t.text "preferences"
    t.bigint "store_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["store_id"], name: "index_spree_gift_card_pdfs_on_store_id"
  end

  create_table "spree_gift_card_transactions", id: :serial, force: :cascade do |t|
    t.decimal "amount", precision: 16, scale: 2
    t.integer "gift_card_id"
    t.integer "order_id"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.string "action"
    t.string "authorization_code"
  end

  create_table "spree_gift_cards", id: :serial, force: :cascade do |t|
    t.integer "variant_id", null: false
    t.integer "line_item_id"
    t.string "email", null: false
    t.string "name"
    t.text "note"
    t.string "code", null: false
    t.datetime "sent_at", precision: nil
    t.decimal "current_value", precision: 16, scale: 2, default: "0.0", null: false
    t.decimal "original_value", precision: 16, scale: 2, default: "0.0", null: false
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.decimal "authorized_amount", precision: 16, scale: 2, default: "0.0", null: false
    t.boolean "enabled", default: false
    t.bigint "client_id"
    t.string "currency"
    t.index ["client_id"], name: "index_spree_gift_cards_on_client_id"
  end

  create_table "spree_givex_cards", force: :cascade do |t|
    t.bigint "transaction_code"
    t.string "givex_number"
    t.string "givex_transaction_reference"
    t.string "customer_email"
    t.decimal "balance", precision: 16, scale: 2
    t.date "expiry_date"
    t.text "receipt_message"
    t.text "comments"
    t.integer "user_id"
    t.integer "line_item_id"
    t.integer "order_id"
    t.integer "line_item_customization_id"
    t.text "givex_response"
    t.string "customer_first_name", default: ""
    t.string "customer_last_name", default: ""
    t.boolean "card_generated", default: false
    t.bigint "store_id"
    t.bigint "client_id"
    t.string "from_email", default: ""
    t.string "invoice_id", default: ""
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "currency", default: ""
    t.string "receipient_phone_number"
    t.integer "send_gift_card_via", default: 1
    t.string "slug"
    t.boolean "bonus", default: false
    t.boolean "active_card", default: false
    t.string "iso_code"
    t.string "check_balance_reponse"
    t.integer "status", default: 0
    t.integer "request_state", default: 0
    t.index ["client_id"], name: "index_spree_givex_cards_on_client_id"
    t.index ["slug"], name: "index_spree_givex_cards_on_slug", unique: true
    t.index ["store_id"], name: "index_spree_givex_cards_on_store_id"
  end

  create_table "spree_hawk_cards", force: :cascade do |t|
    t.text "hawk_response"
    t.bigint "transaction_code"
    t.bigint "bar_code_number"
    t.decimal "balance", precision: 16, scale: 2
    t.date "expiry_date"
    t.integer "pin"
    t.string "supplier_reference_no"
    t.string "url"
    t.string "sku"
    t.string "delivery_email"
    t.string "card_type"
    t.integer "order_id"
    t.integer "user_id"
    t.integer "line_item_id"
    t.string "customer_first_name"
    t.string "customer_last_name"
  end

  create_table "spree_html_components", force: :cascade do |t|
    t.string "type_of_component"
    t.string "name"
    t.integer "position"
    t.integer "html_layout_id"
    t.string "heading"
    t.integer "publish_html_layout_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "no_of_images", default: 4
    t.integer "client_id"
    t.index ["html_layout_id"], name: "index_spree_html_components_on_html_layout_id"
  end

  create_table "spree_html_layouts", force: :cascade do |t|
    t.string "type_of_layout"
    t.integer "html_page_id"
    t.string "name"
    t.boolean "publish", default: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "spree_html_links", force: :cascade do |t|
    t.string "resource_type"
    t.bigint "resource_id"
    t.string "link"
    t.string "name"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "sort_order", default: 1
    t.boolean "is_external_link", default: false
    t.integer "link_type", default: 0
    t.index ["resource_id"], name: "index_spree_html_links_on_resource_id"
    t.index ["resource_type", "resource_id"], name: "index_spree_html_links_on_resource_type_and_resource_id"
  end

  create_table "spree_html_pages", force: :cascade do |t|
    t.string "url"
    t.integer "store_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "spree_html_ui_block_sections", force: :cascade do |t|
    t.string "name"
    t.string "type_of_section"
    t.integer "html_ui_block_id"
    t.string "alt"
    t.string "link"
    t.integer "position"
    t.integer "attachment_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "gallery_image_id"
    t.boolean "is_external_link", default: false
    t.index ["html_ui_block_id"], name: "index_spree_html_ui_block_sections_on_html_ui_block_id"
  end

  create_table "spree_html_ui_blocks", force: :cascade do |t|
    t.string "title"
    t.string "heading"
    t.string "caption"
    t.string "text_allignment"
    t.string "font_color"
    t.integer "position"
    t.string "type_of_html_ui_block"
    t.integer "html_component_id"
    t.integer "parent_id"
    t.string "background_color"
    t.string "alt"
    t.string "link", default: ""
    t.integer "attachment_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "gallery_image_id"
    t.integer "sort_order", default: 1
    t.boolean "is_external_link", default: false
    t.text "banner_item_description", default: ""
    t.string "cta_label", default: ""
    t.string "cta_link", default: ""
    t.string "logo_url", default: ""
    t.index ["html_component_id"], name: "index_spree_html_ui_blocks_on_html_component_id"
  end

  create_table "spree_info_products", force: :cascade do |t|
    t.string "banner_overlay_text"
    t.text "info_introduction"
    t.string "heading_product_description"
    t.string "media_url"
    t.text "info_description"
    t.string "info_price_statement"
    t.string "book_experience_url"
    t.bigint "product_id"
    t.boolean "show_send_gift_card_button"
    t.text "curated_by"
    t.text "last_block"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "media_type", default: 0
    t.index ["product_id"], name: "index_spree_info_products_on_product_id"
  end

  create_table "spree_inventory_units", id: :serial, force: :cascade do |t|
    t.string "state"
    t.bigint "variant_id"
    t.bigint "order_id"
    t.bigint "shipment_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "pending", default: true
    t.bigint "line_item_id"
    t.integer "quantity", default: 1
    t.bigint "original_return_item_id"
    t.index ["line_item_id"], name: "index_spree_inventory_units_on_line_item_id"
    t.index ["order_id"], name: "index_inventory_units_on_order_id"
    t.index ["original_return_item_id"], name: "index_spree_inventory_units_on_original_return_item_id"
    t.index ["shipment_id"], name: "index_inventory_units_on_shipment_id"
    t.index ["variant_id"], name: "index_inventory_units_on_variant_id"
  end

  create_table "spree_invoice_configurations", force: :cascade do |t|
    t.string "brand"
    t.text "address"
    t.string "phone"
    t.string "email"
    t.text "notes"
    t.text "preferences"
    t.bigint "store_id", null: false
    t.index ["store_id"], name: "index_spree_invoice_configurations_on_store_id"
  end

  create_table "spree_json_files", force: :cascade do |t|
    t.bigint "client_id"
    t.string "source"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["client_id"], name: "index_spree_json_files_on_client_id"
  end

  create_table "spree_layout_settings", force: :cascade do |t|
    t.text "preferences"
    t.bigint "store_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["store_id"], name: "index_spree_layout_settings_on_store_id"
  end

  create_table "spree_line_item_customizations", force: :cascade do |t|
    t.string "name"
    t.decimal "price", precision: 16, scale: 2
    t.string "title"
    t.string "value"
    t.integer "customization_option_id"
    t.bigint "line_item_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "field_type"
    t.integer "customization_id"
    t.string "sku"
    t.index ["line_item_id"], name: "index_spree_line_item_customizations_on_line_item_id"
  end

  create_table "spree_line_item_exchange_rates", force: :cascade do |t|
    t.string "from_currency"
    t.string "to_currency"
    t.decimal "exchange_rate", precision: 16, scale: 8, default: "1.0"
    t.float "mark_up", default: 0.0
    t.bigint "line_item_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["line_item_id"], name: "index_spree_line_item_exchange_rates_on_line_item_id"
  end

  create_table "spree_line_items", id: :serial, force: :cascade do |t|
    t.bigint "variant_id"
    t.bigint "order_id"
    t.integer "quantity", null: false
    t.decimal "price", precision: 16, scale: 2, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "currency"
    t.decimal "cost_price", precision: 16, scale: 2
    t.bigint "tax_category_id"
    t.decimal "adjustment_total", precision: 16, scale: 2, default: "0.0"
    t.decimal "additional_tax_total", precision: 16, scale: 2, default: "0.0"
    t.decimal "promo_total", precision: 16, scale: 2, default: "0.0"
    t.decimal "included_tax_total", precision: 16, scale: 2, default: "0.0", null: false
    t.decimal "pre_tax_amount", precision: 16, scale: 4, default: "0.0", null: false
    t.decimal "taxable_adjustment_total", precision: 16, scale: 2, default: "0.0", null: false
    t.decimal "non_taxable_adjustment_total", precision: 16, scale: 2, default: "0.0", null: false
    t.integer "vendor_id"
    t.string "vendor_name"
    t.integer "store_id"
    t.text "message"
    t.boolean "glo_api"
    t.decimal "customizations_total", precision: 16, scale: 2, default: "0.0"
    t.decimal "sub_total", precision: 16, scale: 2, default: "0.0"
    t.decimal "exchange_rate_value", precision: 16, scale: 2, default: "1.0"
    t.decimal "local_area_delivery", precision: 16, scale: 2, default: "0.0"
    t.decimal "wide_area_delivery", precision: 16, scale: 2, default: "0.0"
    t.string "shipping_category", default: ""
    t.boolean "is_gift_card", default: false
    t.string "product_type"
    t.string "delivery_mode", default: "gift"
    t.text "refund_notes"
    t.boolean "digital", default: false
    t.string "receipient_first_name", default: ""
    t.string "receipient_last_name", default: ""
    t.string "receipient_email", default: ""
    t.boolean "show_gft_card_value", default: false
    t.string "status", default: ""
    t.decimal "custom_price", precision: 16, scale: 2, default: "0.0"
    t.string "sender_name", default: ""
    t.string "receipient_phone_number"
    t.integer "send_gift_card_via"
    t.integer "item_exchange_rate", default: 0
    t.integer "shipment_type", default: 0
    t.jsonb "public_metadata"
    t.jsonb "private_metadata"
    t.jsonb "option_values_text", default: []
    t.index ["order_id"], name: "index_spree_line_items_on_order_id"
    t.index ["tax_category_id"], name: "index_spree_line_items_on_tax_category_id"
    t.index ["variant_id"], name: "index_spree_line_items_on_variant_id"
  end

  create_table "spree_link_sources", force: :cascade do |t|
    t.integer "state", default: 0
    t.integer "payment_method_id"
    t.integer "user_id"
    t.string "gateway_reference"
    t.string "url"
    t.datetime "expires_at", precision: nil
    t.jsonb "meta"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["payment_method_id"], name: "index_spree_link_sources_on_payment_method_id"
    t.index ["user_id"], name: "index_spree_link_sources_on_user_id"
  end

  create_table "spree_linked_inventories", force: :cascade do |t|
    t.bigint "vendor_group_id"
    t.string "name"
    t.string "description"
    t.datetime "deleted_at", precision: nil
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.bigint "master_variant_id"
    t.bigint "quantity"
    t.index ["vendor_group_id"], name: "index_spree_inventories_on_vendor_group_id"
  end

  create_table "spree_log_entries", id: :serial, force: :cascade do |t|
    t.string "source_type"
    t.bigint "source_id"
    t.text "details"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["source_id", "source_type"], name: "index_spree_log_entries_on_source_id_and_source_type"
  end

  create_table "spree_markups", force: :cascade do |t|
    t.string "name"
    t.float "value"
    t.integer "currency_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "spree_menu_items", force: :cascade do |t|
    t.string "name", null: false
    t.string "subtitle"
    t.string "destination"
    t.boolean "new_window", default: false
    t.string "item_type"
    t.string "linked_resource_type", default: "Spree::Linkable::Uri"
    t.bigint "linked_resource_id"
    t.string "code"
    t.bigint "parent_id"
    t.bigint "lft", null: false
    t.bigint "rgt", null: false
    t.integer "depth", default: 0, null: false
    t.bigint "menu_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["code"], name: "index_spree_menu_items_on_code"
    t.index ["depth"], name: "index_spree_menu_items_on_depth"
    t.index ["item_type"], name: "index_spree_menu_items_on_item_type"
    t.index ["lft"], name: "index_spree_menu_items_on_lft"
    t.index ["linked_resource_type", "linked_resource_id"], name: "index_spree_menu_items_on_linked_resource"
    t.index ["menu_id"], name: "index_spree_menu_items_on_menu_id"
    t.index ["parent_id"], name: "index_spree_menu_items_on_parent_id"
    t.index ["rgt"], name: "index_spree_menu_items_on_rgt"
  end

  create_table "spree_menus", force: :cascade do |t|
    t.string "name"
    t.string "location"
    t.string "locale"
    t.bigint "store_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["locale"], name: "index_spree_menus_on_locale"
    t.index ["store_id", "location", "locale"], name: "index_spree_menus_on_store_id_and_location_and_locale", unique: true
    t.index ["store_id"], name: "index_spree_menus_on_store_id"
  end

  create_table "spree_notifications", force: :cascade do |t|
    t.text "message"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "store_id"
    t.integer "client_id"
  end

  create_table "spree_notifications_vendors", force: :cascade do |t|
    t.bigint "vendor_id"
    t.bigint "notification_id"
    t.boolean "read", default: false
    t.index ["notification_id"], name: "index_spree_notifications_vendors_on_notification_id"
    t.index ["vendor_id"], name: "index_spree_notifications_vendors_on_vendor_id"
  end

  create_table "spree_oauth_access_grants", force: :cascade do |t|
    t.bigint "resource_owner_id", null: false
    t.bigint "application_id", null: false
    t.string "token", null: false
    t.integer "expires_in", null: false
    t.text "redirect_uri", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "revoked_at", precision: nil
    t.string "scopes"
    t.string "resource_owner_type", null: false
    t.index ["application_id"], name: "index_spree_oauth_access_grants_on_application_id"
    t.index ["resource_owner_id", "resource_owner_type"], name: "polymorphic_owner_oauth_access_grants"
    t.index ["token"], name: "index_spree_oauth_access_grants_on_token", unique: true
  end

  create_table "spree_oauth_access_tokens", force: :cascade do |t|
    t.bigint "resource_owner_id"
    t.bigint "application_id"
    t.string "token", null: false
    t.string "refresh_token"
    t.integer "expires_in"
    t.datetime "revoked_at", precision: nil
    t.datetime "created_at", precision: nil, null: false
    t.string "scopes"
    t.string "previous_refresh_token", default: "", null: false
    t.string "resource_owner_type"
    t.index ["application_id"], name: "index_spree_oauth_access_tokens_on_application_id"
    t.index ["refresh_token"], name: "index_spree_oauth_access_tokens_on_refresh_token", unique: true
    t.index ["resource_owner_id", "resource_owner_type"], name: "polymorphic_owner_oauth_access_tokens"
    t.index ["resource_owner_id"], name: "index_spree_oauth_access_tokens_on_resource_owner_id"
    t.index ["token"], name: "index_spree_oauth_access_tokens_on_token", unique: true
  end

  create_table "spree_oauth_applications", force: :cascade do |t|
    t.string "name", null: false
    t.string "uid", null: false
    t.string "secret", null: false
    t.text "redirect_uri", null: false
    t.string "scopes", default: "", null: false
    t.boolean "confidential", default: true, null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["uid"], name: "index_spree_oauth_applications_on_uid", unique: true
  end

  create_table "spree_option_type_prototypes", id: :serial, force: :cascade do |t|
    t.bigint "prototype_id"
    t.bigint "option_type_id"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.index ["option_type_id"], name: "index_spree_option_type_prototypes_on_option_type_id"
    t.index ["prototype_id", "option_type_id"], name: "spree_option_type_prototypes_prototype_id_option_type_id", unique: true
    t.index ["prototype_id"], name: "index_spree_option_type_prototypes_on_prototype_id"
  end

  create_table "spree_option_type_translations", force: :cascade do |t|
    t.string "name"
    t.string "presentation"
    t.string "locale", null: false
    t.bigint "spree_option_type_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["locale"], name: "index_spree_option_type_translations_on_locale"
    t.index ["spree_option_type_id", "locale"], name: "unique_option_type_id_per_locale", unique: true
  end

  create_table "spree_option_types", id: :serial, force: :cascade do |t|
    t.string "name", limit: 100
    t.string "presentation", limit: 100
    t.integer "position", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "vendor_id"
    t.bigint "client_id"
    t.boolean "filterable", default: true, null: false
    t.jsonb "public_metadata"
    t.jsonb "private_metadata"
    t.index ["client_id"], name: "index_spree_option_types_on_client_id"
    t.index ["filterable"], name: "index_spree_option_types_on_filterable"
    t.index ["name"], name: "index_spree_option_types_on_name"
    t.index ["position"], name: "index_spree_option_types_on_position"
    t.index ["vendor_id"], name: "index_spree_option_types_on_vendor_id"
  end

  create_table "spree_option_value_translations", force: :cascade do |t|
    t.string "name"
    t.string "presentation"
    t.string "locale", null: false
    t.bigint "spree_option_value_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["locale"], name: "index_spree_option_value_translations_on_locale"
    t.index ["spree_option_value_id", "locale"], name: "unique_option_value_id_per_locale", unique: true
  end

  create_table "spree_option_value_variants", id: :serial, force: :cascade do |t|
    t.bigint "variant_id"
    t.bigint "option_value_id"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.index ["option_value_id"], name: "index_spree_option_value_variants_on_option_value_id"
    t.index ["variant_id", "option_value_id"], name: "index_option_values_variants_on_variant_id_and_option_value_id", unique: true
    t.index ["variant_id"], name: "index_spree_option_value_variants_on_variant_id"
  end

  create_table "spree_option_values", id: :serial, force: :cascade do |t|
    t.integer "position"
    t.string "name"
    t.string "presentation"
    t.bigint "option_type_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.jsonb "public_metadata"
    t.jsonb "private_metadata"
    t.index ["name"], name: "index_spree_option_values_on_name"
    t.index ["option_type_id"], name: "index_spree_option_values_on_option_type_id"
    t.index ["position"], name: "index_spree_option_values_on_position"
  end

  create_table "spree_order_promotions", id: :serial, force: :cascade do |t|
    t.bigint "order_id"
    t.bigint "promotion_id"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.index ["order_id"], name: "index_spree_order_promotions_on_order_id"
    t.index ["promotion_id", "order_id"], name: "index_spree_order_promotions_on_promotion_id_and_order_id"
    t.index ["promotion_id"], name: "index_spree_order_promotions_on_promotion_id"
  end

  create_table "spree_order_tags", force: :cascade do |t|
    t.integer "client_id"
    t.string "label_name"
    t.string "intimation_email"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "spree_order_tags_orders", force: :cascade do |t|
    t.bigint "order_id"
    t.bigint "order_tag_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["order_id"], name: "index_spree_order_tags_orders_on_order_id"
    t.index ["order_tag_id"], name: "index_spree_order_tags_orders_on_order_tag_id"
  end

  create_table "spree_orders", id: :serial, force: :cascade do |t|
    t.string "number", limit: 32
    t.decimal "item_total", precision: 16, scale: 2, default: "0.0", null: false
    t.decimal "total", precision: 16, scale: 2, default: "0.0", null: false
    t.string "state"
    t.decimal "adjustment_total", precision: 16, scale: 2, default: "0.0", null: false
    t.bigint "user_id"
    t.datetime "completed_at", precision: nil
    t.bigint "bill_address_id"
    t.bigint "ship_address_id"
    t.decimal "payment_total", precision: 16, scale: 2, default: "0.0"
    t.string "shipment_state"
    t.string "payment_state"
    t.string "email"
    t.text "special_instructions"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "currency"
    t.string "last_ip_address"
    t.bigint "created_by_id"
    t.decimal "shipment_total", precision: 16, scale: 2, default: "0.0", null: false
    t.decimal "additional_tax_total", precision: 16, scale: 2, default: "0.0"
    t.decimal "promo_total", precision: 16, scale: 2, default: "0.0"
    t.string "channel", default: "spree"
    t.decimal "included_tax_total", precision: 16, scale: 2, default: "0.0", null: false
    t.integer "item_count", default: 0
    t.bigint "approver_id"
    t.datetime "approved_at", precision: nil
    t.boolean "confirmation_delivered", default: false
    t.boolean "considered_risky", default: false
    t.string "token"
    t.datetime "canceled_at", precision: nil
    t.bigint "canceler_id"
    t.bigint "store_id"
    t.integer "state_lock_version", default: 0, null: false
    t.decimal "taxable_adjustment_total", precision: 16, scale: 2, default: "0.0", null: false
    t.decimal "non_taxable_adjustment_total", precision: 16, scale: 2, default: "0.0", null: false
    t.string "status", default: "pending"
    t.boolean "glo_promo", default: false
    t.bigint "client_id"
    t.boolean "mailchimp_cart_created"
    t.string "mailchimp_campaign_id"
    t.boolean "paid_partially", default: false
    t.date "pick_up_date"
    t.string "pick_up_time", default: ""
    t.string "delivery_type", default: ""
    t.text "customer_comment"
    t.string "customer_first_name"
    t.string "customer_last_name"
    t.integer "client_order_id", default: 0
    t.string "payment_intent_id"
    t.jsonb "labels", default: {}
    t.boolean "enabled_marketing", default: false
    t.string "cart_token"
    t.string "ts_payment_intent_id"
    t.integer "ts_action", default: 0
    t.string "spo_invoice"
    t.string "spo_genre"
    t.text "preferences"
    t.boolean "news_letter", default: false
    t.text "notes"
    t.integer "bulk_order_id"
    t.bigint "zone_id"
    t.boolean "store_owner_notification_delivered"
    t.jsonb "public_metadata"
    t.jsonb "private_metadata"
    t.text "internal_note"
    t.integer "error_log_status", default: 0
    t.index ["approver_id"], name: "index_spree_orders_on_approver_id"
    t.index ["bill_address_id"], name: "index_spree_orders_on_bill_address_id"
    t.index ["canceler_id"], name: "index_spree_orders_on_canceler_id"
    t.index ["client_id"], name: "index_spree_orders_on_client_id"
    t.index ["completed_at"], name: "index_spree_orders_on_completed_at"
    t.index ["confirmation_delivered"], name: "index_spree_orders_on_confirmation_delivered"
    t.index ["considered_risky"], name: "index_spree_orders_on_considered_risky"
    t.index ["created_by_id"], name: "index_spree_orders_on_created_by_id"
    t.index ["email"], name: "index_spree_orders_on_email"
    t.index ["number"], name: "index_spree_orders_on_number", unique: true
    t.index ["ship_address_id"], name: "index_spree_orders_on_ship_address_id"
    t.index ["store_id"], name: "index_spree_orders_on_store_id"
    t.index ["token"], name: "index_spree_orders_on_token"
    t.index ["user_id", "created_by_id"], name: "index_spree_orders_on_user_id_and_created_by_id"
    t.index ["user_id"], name: "index_spree_orders_on_user_id"
  end

  create_table "spree_otps", force: :cascade do |t|
    t.string "secret_key"
    t.boolean "verified", default: false
    t.bigint "user_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["user_id"], name: "index_spree_otps_on_user_id"
  end

  create_table "spree_pages", force: :cascade do |t|
    t.string "title"
    t.integer "sort_order"
    t.string "status"
    t.string "heading"
    t.text "content"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.bigint "client_id"
    t.string "url", default: ""
    t.string "meta_desc", default: ""
    t.boolean "static_page", default: false
    t.index ["client_id"], name: "index_spree_pages_on_client_id"
  end

  create_table "spree_pages_stores", force: :cascade do |t|
    t.bigint "store_id"
    t.bigint "page_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["page_id"], name: "index_spree_pages_stores_on_page_id"
    t.index ["store_id"], name: "index_spree_pages_stores_on_store_id"
  end

  create_table "spree_payment_capture_events", id: :serial, force: :cascade do |t|
    t.decimal "amount", precision: 16, scale: 2, default: "0.0"
    t.bigint "payment_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["payment_id"], name: "index_spree_payment_capture_events_on_payment_id"
  end

  create_table "spree_payment_intents", force: :cascade do |t|
    t.string "track_id"
    t.decimal "amount", precision: 16, scale: 2
    t.string "currency"
    t.string "method_type"
    t.string "intentable_type"
    t.integer "intentable_id"
    t.integer "order_id"
    t.integer "state", default: 0
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["order_id"], name: "index_spree_payment_intents_on_order_id"
  end

  create_table "spree_payment_methods", id: :serial, force: :cascade do |t|
    t.string "type"
    t.string "name"
    t.text "description"
    t.boolean "active", default: true
    t.datetime "deleted_at", precision: nil
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "display_on", default: "both"
    t.boolean "auto_capture"
    t.text "preferences"
    t.integer "position", default: 0
    t.bigint "client_id"
    t.text "payment_options", default: [], array: true
    t.jsonb "public_metadata"
    t.jsonb "private_metadata"
    t.jsonb "settings"
    t.index ["client_id"], name: "index_spree_payment_methods_on_client_id"
    t.index ["id", "type"], name: "index_spree_payment_methods_on_id_and_type"
    t.index ["id"], name: "index_spree_payment_methods_on_id"
  end

  create_table "spree_payment_methods_stores", id: false, force: :cascade do |t|
    t.bigint "payment_method_id"
    t.bigint "store_id"
    t.datetime "created_at", precision: nil, default: "2024-01-04 12:01:10", null: false
    t.datetime "updated_at", precision: nil, default: "2024-01-04 12:01:10", null: false
    t.string "payment_option"
    t.string "payment_option_display"
    t.integer "apple_pay_domains", default: 1
    t.text "preferences"
    t.index ["payment_method_id"], name: "index_spree_payment_methods_stores_on_payment_method_id"
    t.index ["store_id"], name: "index_spree_payment_methods_stores_on_store_id"
  end

  create_table "spree_payment_sources", force: :cascade do |t|
    t.string "gateway_payment_profile_id"
    t.string "type"
    t.bigint "payment_method_id"
    t.bigint "user_id"
    t.jsonb "public_metadata"
    t.jsonb "private_metadata"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["payment_method_id"], name: "index_spree_payment_sources_on_payment_method_id"
    t.index ["type", "gateway_payment_profile_id"], name: "index_payment_sources_on_type_and_gateway_payment_profile_id", unique: true
    t.index ["type"], name: "index_spree_payment_sources_on_type"
    t.index ["user_id"], name: "index_spree_payment_sources_on_user_id"
  end

  create_table "spree_payments", id: :serial, force: :cascade do |t|
    t.decimal "amount", precision: 16, scale: 2, default: "0.0", null: false
    t.bigint "order_id"
    t.string "source_type"
    t.bigint "source_id"
    t.bigint "payment_method_id"
    t.string "state"
    t.string "response_code"
    t.string "avs_response"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "number"
    t.string "cvv_response_code"
    t.string "cvv_response_message"
    t.string "braintree_token"
    t.string "braintree_nonce"
    t.jsonb "meta"
    t.string "intent_client_key"
    t.jsonb "public_metadata"
    t.jsonb "private_metadata"
    t.index ["number"], name: "index_spree_payments_on_number", unique: true
    t.index ["order_id"], name: "index_spree_payments_on_order_id"
    t.index ["payment_method_id"], name: "index_spree_payments_on_payment_method_id"
    t.index ["source_id", "source_type"], name: "index_spree_payments_on_source_id_and_source_type"
  end

  create_table "spree_paypal_express_checkouts", id: :serial, force: :cascade do |t|
    t.string "payer_id"
    t.string "state", default: "complete"
    t.string "refund_transaction_id"
    t.datetime "refunded_at", precision: nil
    t.string "refund_type"
    t.datetime "created_at", precision: nil
    t.string "order_id"
    t.string "transaction_id"
    t.index ["order_id"], name: "index_spree_paypal_express_checkouts_on_order_id"
    t.index ["transaction_id"], name: "index_spree_paypal_express_checkouts_on_transaction_id"
  end

  create_table "spree_personalizations", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "spree_personas", force: :cascade do |t|
    t.string "name"
    t.integer "persona_code", default: 0
    t.bigint "client_id"
    t.text "store_ids", default: [], array: true
    t.text "menu_item_ids", default: [], array: true
    t.text "campaign_ids", default: [], array: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["client_id"], name: "index_spree_personas_on_client_id"
  end

  create_table "spree_preferences", id: :serial, force: :cascade do |t|
    t.text "value"
    t.string "key"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_spree_preferences_on_key", unique: true
  end

  create_table "spree_prices", id: :serial, force: :cascade do |t|
    t.bigint "variant_id", null: false
    t.decimal "amount", precision: 16, scale: 2
    t.string "currency"
    t.datetime "deleted_at", precision: nil
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.decimal "compare_at_amount", precision: 10, scale: 2
    t.index ["deleted_at"], name: "index_spree_prices_on_deleted_at"
    t.index ["variant_id", "currency"], name: "index_spree_prices_on_variant_id_and_currency"
    t.index ["variant_id"], name: "index_spree_prices_on_variant_id"
  end

  create_table "spree_product_currency_prices", force: :cascade do |t|
    t.string "from_currency"
    t.string "to_currency"
    t.integer "client_id"
    t.integer "vendor_id"
    t.integer "product_id"
    t.integer "vendor_country_id"
    t.decimal "non_exchanged_price", precision: 16, scale: 2
    t.decimal "price", precision: 16, scale: 2
    t.decimal "local_area_price", precision: 16, scale: 2
    t.decimal "wide_area_price", precision: 16, scale: 2
    t.decimal "restricted_area_price", precision: 16, scale: 2
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.decimal "sale_price", precision: 16, scale: 2, default: "0.0"
    t.text "local_store_ids", default: [], array: true
    t.text "taxes", default: [], array: true
    t.float "exchange_rate_value", default: 1.0
    t.index ["client_id"], name: "index_spree_product_currency_prices_on_client_id"
    t.index ["product_id"], name: "index_spree_product_currency_prices_on_product_id"
    t.index ["vendor_country_id"], name: "index_spree_product_currency_prices_on_vendor_country_id"
    t.index ["vendor_id"], name: "index_spree_product_currency_prices_on_vendor_id"
  end

  create_table "spree_product_option_types", id: :serial, force: :cascade do |t|
    t.integer "position"
    t.bigint "product_id"
    t.bigint "option_type_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["option_type_id"], name: "index_spree_product_option_types_on_option_type_id"
    t.index ["position"], name: "index_spree_product_option_types_on_position"
    t.index ["product_id"], name: "index_spree_product_option_types_on_product_id"
  end

  create_table "spree_product_promotion_rules", id: :serial, force: :cascade do |t|
    t.bigint "product_id"
    t.bigint "promotion_rule_id"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.index ["product_id"], name: "index_products_promotion_rules_on_product_id"
    t.index ["promotion_rule_id", "product_id"], name: "index_products_promotion_rules_on_promotion_rule_and_product"
  end

  create_table "spree_product_properties", id: :serial, force: :cascade do |t|
    t.string "value"
    t.bigint "product_id"
    t.bigint "property_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "position", default: 0
    t.boolean "show_property", default: true
    t.string "filter_param"
    t.index ["filter_param"], name: "index_spree_product_properties_on_filter_param"
    t.index ["position"], name: "index_spree_product_properties_on_position"
    t.index ["product_id"], name: "index_product_properties_on_product_id"
    t.index ["property_id"], name: "index_spree_product_properties_on_property_id"
  end

  create_table "spree_product_property_translations", force: :cascade do |t|
    t.string "value"
    t.string "filter_param"
    t.string "locale", null: false
    t.bigint "spree_product_property_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["locale"], name: "index_spree_product_property_translations_on_locale"
    t.index ["spree_product_property_id", "locale"], name: "unique_product_property_id_per_locale", unique: true
  end

  create_table "spree_product_translations", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.string "locale", null: false
    t.bigint "spree_product_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "meta_description"
    t.string "meta_keywords"
    t.string "meta_title"
    t.string "slug"
    t.datetime "deleted_at", precision: nil
    t.index ["deleted_at"], name: "index_spree_product_translations_on_deleted_at"
    t.index ["locale", "slug"], name: "unique_slug_per_locale", unique: true
    t.index ["locale"], name: "index_spree_product_translations_on_locale"
    t.index ["spree_product_id", "locale"], name: "unique_product_id_per_locale", unique: true
  end

  create_table "spree_products", id: :serial, force: :cascade do |t|
    t.string "name", default: ""
    t.text "description"
    t.datetime "available_on", precision: nil
    t.datetime "deleted_at", precision: nil
    t.string "slug"
    t.text "meta_description"
    t.string "meta_keywords"
    t.bigint "tax_category_id"
    t.bigint "shipping_category_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "promotionable", default: true
    t.string "meta_title"
    t.datetime "discontinue_on", precision: nil
    t.integer "vendor_id"
    t.boolean "trashbin", default: false
    t.string "status", default: "draft"
    t.text "long_description"
    t.boolean "gift_messages", default: false
    t.string "vendor_sku", default: ""
    t.decimal "avg_rating", precision: 7, scale: 5, default: "0.0", null: false
    t.integer "reviews_count", default: 0, null: false
    t.boolean "is_gift_card", default: false, null: false
    t.decimal "local_area_delivery", precision: 16, scale: 2, default: "0.0"
    t.decimal "wide_area_delivery", precision: 16, scale: 2, default: "0.0"
    t.text "category_state"
    t.integer "magento_id"
    t.integer "manufacturing_lead_time", default: 1
    t.decimal "restricted_area_delivery", precision: 16, scale: 2, default: "0.0"
    t.integer "delivery_days_to_same_country"
    t.integer "delivery_days_to_americas"
    t.integer "delivery_days_to_africa"
    t.integer "delivery_days_to_australia"
    t.integer "delivery_days_to_asia"
    t.integer "delivery_days_to_europe"
    t.integer "delivery_days_to_restricted_area"
    t.string "url_key", default: ""
    t.boolean "stock_status", default: true
    t.decimal "sale_price", precision: 16, scale: 2, default: "0.0"
    t.integer "calculated_days_to_same_country", default: 0
    t.integer "calculated_days_to_restricted_area", default: 0
    t.integer "calculated_days_to_asia", default: 0
    t.integer "calculated_days_to_africa", default: 0
    t.integer "calculated_days_to_americas", default: 0
    t.integer "calculated_days_to_europe", default: 0
    t.integer "calculated_days_to_australia", default: 0
    t.bigint "client_id"
    t.boolean "featured"
    t.text "delivery_details", default: ""
    t.integer "count_on_hand"
    t.datetime "sale_start_date", precision: nil
    t.datetime "sale_end_date", precision: nil
    t.boolean "on_sale", default: false
    t.boolean "product_is_gift_card", default: false
    t.boolean "hide_price", default: false
    t.boolean "disable_cart", default: false
    t.integer "minimum_order_quantity", default: 0
    t.integer "pack_size", default: 1
    t.decimal "rrp", precision: 16, scale: 2
    t.string "shopify_id"
    t.boolean "digital", default: false
    t.string "product_type", default: "gift"
    t.text "blocked_dates", default: [], array: true
    t.string "delivery_mode"
    t.text "color_swatches", default: [], array: true
    t.text "size_swatches", default: [], array: true
    t.string "digital_service_provider", default: ""
    t.string "prefix", default: ""
    t.string "suffix", default: ""
    t.string "ts_type", default: ""
    t.string "campaign_code", default: ""
    t.boolean "hide_from_search", default: false
    t.integer "default_quantity"
    t.boolean "disable_quantity", default: false
    t.integer "voucher_email_image", default: 0
    t.string "intimation_emails"
    t.boolean "recipient_details_on_detail_page", default: false
    t.integer "send_gift_card_via", default: 1
    t.string "brand_name"
    t.string "recipient_email_link"
    t.boolean "enable_product_info", default: false
    t.boolean "single_page", default: false
    t.text "preferences"
    t.boolean "linked", default: false
    t.decimal "unit_cost_price", precision: 10, scale: 2, default: "0.0"
    t.string "barcode_number", default: ""
    t.string "type"
    t.bigint "parent_id"
    t.date "effective_date"
    t.boolean "daily_stock", default: false
    t.bigint "product_batch_id"
    t.boolean "track_inventory", default: true
    t.jsonb "public_metadata"
    t.jsonb "private_metadata"
    t.datetime "make_active_at", precision: nil
    t.index ["available_on"], name: "index_spree_products_on_available_on"
    t.index ["client_id"], name: "index_spree_products_on_client_id"
    t.index ["deleted_at"], name: "index_spree_products_on_deleted_at"
    t.index ["discontinue_on"], name: "index_spree_products_on_discontinue_on"
    t.index ["make_active_at"], name: "index_spree_products_on_make_active_at"
    t.index ["name"], name: "index_spree_products_on_name"
    t.index ["product_batch_id"], name: "index_spree_products_on_product_batch_id"
    t.index ["shipping_category_id"], name: "index_spree_products_on_shipping_category_id"
    t.index ["slug"], name: "index_spree_products_on_slug", unique: true
    t.index ["status", "deleted_at"], name: "index_spree_products_on_status_and_deleted_at"
    t.index ["status"], name: "index_spree_products_on_status"
    t.index ["tax_category_id"], name: "index_spree_products_on_tax_category_id"
    t.index ["vendor_id", "stock_status"], name: "index_spree_products_on_vendor_id_and_stock_status"
    t.index ["vendor_id", "trashbin"], name: "index_spree_products_on_vendor_id_and_trashbin"
    t.index ["vendor_id"], name: "index_spree_products_on_vendor_id"
  end

  create_table "spree_products_classifications", force: :cascade do |t|
    t.integer "product_id"
    t.integer "taxon_id"
    t.integer "position"
    t.integer "client_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "store_ids", default: [], array: true
    t.index ["client_id"], name: "index_spree_products_classifications_on_client_id"
    t.index ["position"], name: "index_spree_products_classifications_on_position"
    t.index ["product_id"], name: "index_spree_products_classifications_on_product_id"
    t.index ["taxon_id"], name: "index_spree_products_classifications_on_taxon_id"
  end

  create_table "spree_products_stores", id: false, force: :cascade do |t|
    t.bigint "product_id"
    t.bigint "store_id"
    t.datetime "created_at", precision: nil, default: "2024-01-01 12:21:17", null: false
    t.datetime "updated_at", precision: nil, default: "2024-01-01 12:21:17", null: false
    t.index ["product_id"], name: "index_spree_products_stores_on_product_id"
    t.index ["store_id"], name: "index_spree_products_stores_on_store_id"
  end

  create_table "spree_products_taxons", id: :serial, force: :cascade do |t|
    t.bigint "product_id"
    t.bigint "taxon_id"
    t.integer "position"
    t.bigint "store_id"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.index ["position"], name: "index_spree_products_taxons_on_position"
    t.index ["product_id"], name: "index_spree_products_taxons_on_product_id"
    t.index ["store_id"], name: "index_spree_products_taxons_on_store_id"
    t.index ["taxon_id"], name: "index_spree_products_taxons_on_taxon_id"
  end

  create_table "spree_promotion_action_line_items", id: :serial, force: :cascade do |t|
    t.bigint "promotion_action_id"
    t.bigint "variant_id"
    t.integer "quantity", default: 1
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.index ["promotion_action_id"], name: "index_spree_promotion_action_line_items_on_promotion_action_id"
    t.index ["variant_id"], name: "index_spree_promotion_action_line_items_on_variant_id"
  end

  create_table "spree_promotion_actions", id: :serial, force: :cascade do |t|
    t.bigint "promotion_id"
    t.integer "position"
    t.string "type"
    t.datetime "deleted_at", precision: nil
    t.boolean "exclude_sale_items", default: false
    t.text "preferences"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.index ["deleted_at"], name: "index_spree_promotion_actions_on_deleted_at"
    t.index ["id", "type"], name: "index_spree_promotion_actions_on_id_and_type"
    t.index ["promotion_id"], name: "index_spree_promotion_actions_on_promotion_id"
  end

  create_table "spree_promotion_categories", id: :serial, force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "code"
    t.bigint "client_id"
    t.index ["client_id"], name: "index_spree_promotion_categories_on_client_id"
  end

  create_table "spree_promotion_rule_taxons", id: :serial, force: :cascade do |t|
    t.bigint "taxon_id"
    t.bigint "promotion_rule_id"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.index ["promotion_rule_id"], name: "index_spree_promotion_rule_taxons_on_promotion_rule_id"
    t.index ["taxon_id"], name: "index_spree_promotion_rule_taxons_on_taxon_id"
  end

  create_table "spree_promotion_rule_users", id: :serial, force: :cascade do |t|
    t.bigint "user_id"
    t.bigint "promotion_rule_id"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.index ["promotion_rule_id"], name: "index_promotion_rules_users_on_promotion_rule_id"
    t.index ["user_id", "promotion_rule_id"], name: "index_promotion_rules_users_on_user_id_and_promotion_rule_id"
  end

  create_table "spree_promotion_rules", id: :serial, force: :cascade do |t|
    t.bigint "promotion_id"
    t.bigint "user_id"
    t.bigint "product_group_id"
    t.string "type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "code"
    t.text "preferences"
    t.index ["product_group_id"], name: "index_promotion_rules_on_product_group_id"
    t.index ["promotion_id"], name: "index_spree_promotion_rules_on_promotion_id"
    t.index ["user_id"], name: "index_promotion_rules_on_user_id"
  end

  create_table "spree_promotion_rules_stores", id: false, force: :cascade do |t|
    t.integer "promotion_rule_id"
    t.integer "store_id"
  end

  create_table "spree_promotions", id: :serial, force: :cascade do |t|
    t.string "description"
    t.datetime "expires_at", precision: nil
    t.datetime "starts_at", precision: nil
    t.string "name"
    t.string "type"
    t.integer "usage_limit"
    t.string "match_policy", default: "all"
    t.string "code"
    t.boolean "advertise", default: false
    t.string "path"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "promotion_category_id"
    t.bigint "client_id"
    t.jsonb "public_metadata"
    t.jsonb "private_metadata"
    t.index ["advertise"], name: "index_spree_promotions_on_advertise"
    t.index ["client_id"], name: "index_spree_promotions_on_client_id"
    t.index ["code", "client_id"], name: "index_spree_promotions_on_code_and_client_id", unique: true
    t.index ["code"], name: "index_spree_promotions_on_code"
    t.index ["expires_at"], name: "index_spree_promotions_on_expires_at"
    t.index ["id", "type"], name: "index_spree_promotions_on_id_and_type"
    t.index ["path"], name: "index_spree_promotions_on_path"
    t.index ["promotion_category_id"], name: "index_spree_promotions_on_promotion_category_id"
    t.index ["starts_at"], name: "index_spree_promotions_on_starts_at"
  end

  create_table "spree_promotions_stores", force: :cascade do |t|
    t.bigint "promotion_id"
    t.bigint "store_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["promotion_id", "store_id"], name: "index_spree_promotions_stores_on_promotion_id_and_store_id", unique: true
    t.index ["promotion_id"], name: "index_spree_promotions_stores_on_promotion_id"
    t.index ["store_id"], name: "index_spree_promotions_stores_on_store_id"
  end

  create_table "spree_properties", id: :serial, force: :cascade do |t|
    t.string "name"
    t.string "presentation"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "vendor_id"
    t.bigint "client_id"
    t.boolean "filterable", default: false
    t.text "values", default: ""
    t.string "filter_param"
    t.jsonb "public_metadata"
    t.jsonb "private_metadata"
    t.index ["client_id"], name: "index_spree_properties_on_client_id"
    t.index ["filter_param"], name: "index_spree_properties_on_filter_param"
    t.index ["name"], name: "index_spree_properties_on_name"
    t.index ["vendor_id"], name: "index_spree_properties_on_vendor_id"
  end

  create_table "spree_properties_stores", force: :cascade do |t|
    t.bigint "store_id"
    t.bigint "property_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["property_id"], name: "index_spree_properties_stores_on_property_id"
    t.index ["store_id"], name: "index_spree_properties_stores_on_store_id"
  end

  create_table "spree_property_prototypes", id: :serial, force: :cascade do |t|
    t.bigint "prototype_id"
    t.bigint "property_id"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.index ["property_id"], name: "index_spree_property_prototypes_on_property_id"
    t.index ["prototype_id", "property_id"], name: "index_property_prototypes_on_prototype_id_and_property_id", unique: true
    t.index ["prototype_id"], name: "index_spree_property_prototypes_on_prototype_id"
  end

  create_table "spree_property_translations", force: :cascade do |t|
    t.string "name"
    t.string "presentation"
    t.string "filter_param"
    t.string "locale", null: false
    t.bigint "spree_property_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["locale"], name: "index_spree_property_translations_on_locale"
    t.index ["spree_property_id", "locale"], name: "unique_property_id_per_locale", unique: true
  end

  create_table "spree_prototype_taxons", id: :serial, force: :cascade do |t|
    t.bigint "taxon_id"
    t.bigint "prototype_id"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.index ["prototype_id", "taxon_id"], name: "index_spree_prototype_taxons_on_prototype_id_and_taxon_id"
    t.index ["prototype_id"], name: "index_spree_prototype_taxons_on_prototype_id"
    t.index ["taxon_id"], name: "index_spree_prototype_taxons_on_taxon_id"
  end

  create_table "spree_prototypes", id: :serial, force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "client_id"
    t.jsonb "public_metadata"
    t.jsonb "private_metadata"
    t.index ["client_id"], name: "index_spree_prototypes_on_client_id"
  end

  create_table "spree_publish_html_layouts", force: :cascade do |t|
    t.string "type_of_layout"
    t.integer "html_page_id"
    t.string "name"
    t.integer "version_number"
    t.boolean "active", default: false
    t.boolean "publish", default: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["active"], name: "index_spree_publish_html_layouts_on_active"
    t.index ["html_page_id"], name: "index_spree_publish_html_layouts_on_html_page_id"
    t.index ["publish", "active", "html_page_id"], name: "publish_active_html_page_index"
    t.index ["publish", "active"], name: "index_spree_publish_html_layouts_on_publish_and_active"
    t.index ["publish"], name: "index_spree_publish_html_layouts_on_publish"
  end

  create_table "spree_questions", force: :cascade do |t|
    t.string "title"
    t.boolean "is_replied", default: false
    t.boolean "archived", default: false
    t.integer "vendor_id"
    t.integer "product_id"
    t.string "status", default: "pending"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "guest_email"
    t.string "guest_name"
    t.integer "customer_id"
    t.integer "store_id"
    t.string "questionable_type"
    t.bigint "questionable_id"
    t.index ["questionable_type", "questionable_id"], name: "index_spree_questions_on_questionable_type_and_questionable_id"
  end

  create_table "spree_redirects", force: :cascade do |t|
    t.string "type_redirect"
    t.string "from"
    t.string "to"
    t.integer "client_id"
    t.integer "store_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "spree_refund_reasons", id: :serial, force: :cascade do |t|
    t.string "name"
    t.boolean "active", default: true
    t.boolean "mutable", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "client_id"
    t.index "lower((name)::text), client_id", name: "index_spree_refund_reasons_on_lower_name_and_client_id", unique: true
    t.index ["client_id"], name: "index_spree_refund_reasons_on_client_id"
  end

  create_table "spree_refunds", id: :serial, force: :cascade do |t|
    t.bigint "payment_id"
    t.decimal "amount", precision: 16, scale: 2, default: "0.0", null: false
    t.string "transaction_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "refund_reason_id"
    t.bigint "reimbursement_id"
    t.text "notes"
    t.integer "user_id"
    t.integer "order_id"
    t.jsonb "public_metadata"
    t.jsonb "private_metadata"
    t.integer "payment_refund_type", default: 0
    t.integer "state", default: 0
    t.index ["payment_id"], name: "index_spree_refunds_on_payment_id"
    t.index ["refund_reason_id"], name: "index_refunds_on_refund_reason_id"
    t.index ["reimbursement_id"], name: "index_spree_refunds_on_reimbursement_id"
  end

  create_table "spree_registrations", force: :cascade do |t|
    t.bigint "user_id"
    t.bigint "store_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["store_id"], name: "index_spree_registrations_on_store_id"
    t.index ["user_id"], name: "index_spree_registrations_on_user_id"
  end

  create_table "spree_reimbursement_credits", id: :serial, force: :cascade do |t|
    t.decimal "amount", precision: 16, scale: 2, default: "0.0", null: false
    t.bigint "reimbursement_id"
    t.bigint "creditable_id"
    t.string "creditable_type"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.index ["creditable_id", "creditable_type"], name: "index_reimbursement_credits_on_creditable_id_and_type"
    t.index ["reimbursement_id"], name: "index_spree_reimbursement_credits_on_reimbursement_id"
  end

  create_table "spree_reimbursement_types", id: :serial, force: :cascade do |t|
    t.string "name"
    t.boolean "active", default: true
    t.boolean "mutable", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "type"
    t.bigint "client_id"
    t.index ["client_id"], name: "index_spree_reimbursement_types_on_client_id"
    t.index ["name", "client_id"], name: "index_spree_reimbursement_types_on_name_and_client_id", unique: true
    t.index ["type"], name: "index_spree_reimbursement_types_on_type"
  end

  create_table "spree_reimbursements", id: :serial, force: :cascade do |t|
    t.string "number"
    t.string "reimbursement_status"
    t.bigint "customer_return_id"
    t.bigint "order_id"
    t.decimal "total", precision: 16, scale: 2
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "status", default: 1
    t.index ["customer_return_id"], name: "index_spree_reimbursements_on_customer_return_id"
    t.index ["number"], name: "index_spree_reimbursements_on_number", unique: true
    t.index ["order_id"], name: "index_spree_reimbursements_on_order_id"
  end

  create_table "spree_relation_types", id: :serial, force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.string "applies_to"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.bigint "client_id"
    t.index ["client_id"], name: "index_spree_relation_types_on_client_id"
  end

  create_table "spree_relations", id: :serial, force: :cascade do |t|
    t.bigint "relation_type_id"
    t.string "relatable_type"
    t.bigint "relatable_id"
    t.string "related_to_type"
    t.bigint "related_to_id"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.decimal "discount_amount", precision: 16, scale: 2, default: "0.0"
    t.integer "position"
  end

  create_table "spree_reports", force: :cascade do |t|
    t.string "feed_type"
    t.string "email"
    t.integer "client_id"
    t.integer "store_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["store_id", "id"], name: "index_spree_reports_on_store_id_and_id"
    t.index ["store_id"], name: "index_spree_reports_on_store_id"
  end

  create_table "spree_return_authorization_reasons", id: :serial, force: :cascade do |t|
    t.string "name"
    t.boolean "active", default: true
    t.boolean "mutable", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "client_id"
    t.index ["client_id"], name: "index_spree_return_authorization_reasons_on_client_id"
    t.index ["name", "client_id"], name: "index_spree_return_authorization_reasons_on_name_and_client_id", unique: true
  end

  create_table "spree_return_authorizations", id: :serial, force: :cascade do |t|
    t.string "number"
    t.string "state"
    t.bigint "order_id"
    t.text "memo"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.bigint "stock_location_id"
    t.bigint "return_authorization_reason_id"
    t.bigint "client_id"
    t.index ["client_id"], name: "index_spree_return_authorizations_on_client_id"
    t.index ["number"], name: "index_spree_return_authorizations_on_number", unique: true
    t.index ["order_id"], name: "index_spree_return_authorizations_on_order_id"
    t.index ["return_authorization_reason_id"], name: "index_return_authorizations_on_return_authorization_reason_id"
    t.index ["stock_location_id"], name: "index_spree_return_authorizations_on_stock_location_id"
  end

  create_table "spree_return_items", id: :serial, force: :cascade do |t|
    t.bigint "return_authorization_id"
    t.bigint "inventory_unit_id"
    t.bigint "exchange_variant_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.decimal "pre_tax_amount", precision: 16, scale: 4, default: "0.0", null: false
    t.decimal "included_tax_total", precision: 16, scale: 4, default: "0.0", null: false
    t.decimal "additional_tax_total", precision: 16, scale: 4, default: "0.0", null: false
    t.string "reception_status"
    t.string "acceptance_status"
    t.bigint "customer_return_id"
    t.bigint "reimbursement_id"
    t.text "acceptance_status_errors"
    t.bigint "preferred_reimbursement_type_id"
    t.bigint "override_reimbursement_type_id"
    t.boolean "resellable", default: true, null: false
    t.index ["customer_return_id"], name: "index_return_items_on_customer_return_id"
    t.index ["exchange_variant_id"], name: "index_spree_return_items_on_exchange_variant_id"
    t.index ["inventory_unit_id"], name: "index_spree_return_items_on_inventory_unit_id"
    t.index ["override_reimbursement_type_id"], name: "index_spree_return_items_on_override_reimbursement_type_id"
    t.index ["preferred_reimbursement_type_id"], name: "index_spree_return_items_on_preferred_reimbursement_type_id"
    t.index ["reimbursement_id"], name: "index_spree_return_items_on_reimbursement_id"
    t.index ["return_authorization_id"], name: "index_spree_return_items_on_return_authorization_id"
  end

  create_table "spree_reviews", id: :serial, force: :cascade do |t|
    t.bigint "product_id"
    t.string "name"
    t.string "location"
    t.integer "rating"
    t.text "title"
    t.text "review"
    t.boolean "approved", default: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.bigint "user_id"
    t.string "ip_address"
    t.string "locale", default: "en"
    t.boolean "show_identifier", default: true
    t.index ["show_identifier"], name: "index_spree_reviews_on_show_identifier"
  end

  create_table "spree_role_users", id: :serial, force: :cascade do |t|
    t.bigint "role_id"
    t.bigint "user_id"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.index ["role_id"], name: "index_spree_role_users_on_role_id"
    t.index ["user_id"], name: "index_spree_role_users_on_user_id"
  end

  create_table "spree_roles", id: :serial, force: :cascade do |t|
    t.string "name"
    t.bigint "client_id"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.index ["client_id"], name: "index_spree_roles_on_client_id"
    t.index ["name", "client_id"], name: "index_spree_roles_on_name_and_client_id", unique: true
  end

  create_table "spree_sale_analyses", force: :cascade do |t|
    t.string "order_number"
    t.string "storefront"
    t.string "time_zone"
    t.datetime "date_placed", precision: nil
    t.string "status"
    t.string "customer"
    t.string "currency"
    t.datetime "delivery_pickup_date", precision: nil
    t.datetime "shipped_date", precision: nil
    t.string "delivery_pickup_time"
    t.string "shipped_time"
    t.decimal "tax_inclusive"
    t.decimal "additional_tax"
    t.string "tags"
    t.decimal "total"
    t.string "vendor"
    t.datetime "time_placed", precision: nil
    t.string "order_status"
    t.string "customer_full_name"
    t.string "customer_address"
    t.string "customer_first_name"
    t.string "customer_last_name"
    t.string "shipping_delivery_country"
    t.string "customer_phone"
    t.string "customer_email"
    t.string "product_name"
    t.string "product_sku"
    t.string "vendor_sku"
    t.string "variant"
    t.integer "product_quantity"
    t.decimal "product_price"
    t.string "order_currency"
    t.string "vendor_currency"
    t.decimal "exchange_rate"
    t.decimal "sub_total"
    t.decimal "shipping_amount"
    t.decimal "total_shipping_amount"
    t.decimal "discount_amount"
    t.decimal "associated_order_value"
    t.string "shipping_method"
    t.text "gift_card_number"
    t.text "gift_card_iso_number"
    t.text "special_message"
    t.string "card_type"
    t.string "recipient_name"
    t.string "recipient_first_name"
    t.string "recipient_last_name"
    t.string "recipient_email"
    t.string "recipient_phone_number"
    t.string "marketing_enabled"
    t.string "product_tag"
    t.string "promo_code"
    t.string "payment_method"
    t.string "order_shipped"
    t.integer "order_id"
    t.integer "line_item_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.decimal "order_subtotal", precision: 16, scale: 2, default: "0.0", null: false
    t.decimal "unit_cost_price", precision: 10, scale: 2, default: "0.0"
    t.string "barcode_number", default: ""
    t.string "brand_name", default: ""
    t.string "product_card_type", default: ""
  end

  create_table "spree_shipments", id: :serial, force: :cascade do |t|
    t.string "tracking"
    t.string "number"
    t.decimal "cost", precision: 16, scale: 2, default: "0.0"
    t.datetime "shipped_at", precision: nil
    t.bigint "order_id"
    t.bigint "address_id"
    t.string "state"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "stock_location_id"
    t.decimal "adjustment_total", precision: 16, scale: 2, default: "0.0"
    t.decimal "additional_tax_total", precision: 16, scale: 2, default: "0.0"
    t.decimal "promo_total", precision: 16, scale: 2, default: "0.0"
    t.decimal "included_tax_total", precision: 16, scale: 2, default: "0.0", null: false
    t.decimal "pre_tax_amount", precision: 16, scale: 4, default: "0.0", null: false
    t.decimal "taxable_adjustment_total", precision: 16, scale: 2, default: "0.0", null: false
    t.decimal "non_taxable_adjustment_total", precision: 16, scale: 2, default: "0.0", null: false
    t.integer "line_item_id"
    t.integer "vendor_id"
    t.string "delivery_type", default: ""
    t.date "delivery_pickup_date"
    t.string "delivery_pickup_time", default: ""
    t.string "delivery_mode", default: ""
    t.text "lalamove_quotation_response", default: ""
    t.text "lalamove_order_response", default: ""
    t.string "lalamove_order_id", default: ""
    t.string "delivery_pickup_date_zone"
    t.datetime "card_generation_datetime", precision: nil
    t.string "fulfilment_status", default: "pending"
    t.jsonb "public_metadata"
    t.jsonb "private_metadata"
    t.index ["address_id"], name: "index_spree_shipments_on_address_id"
    t.index ["number"], name: "index_spree_shipments_on_number", unique: true
    t.index ["order_id"], name: "index_spree_shipments_on_order_id"
    t.index ["stock_location_id"], name: "index_spree_shipments_on_stock_location_id"
  end

  create_table "spree_shipping_categories", id: :serial, force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "client_id"
    t.boolean "is_weighted", default: false
    t.index ["client_id"], name: "index_spree_shipping_categories_on_client_id"
    t.index ["name"], name: "index_spree_shipping_categories_on_name"
  end

  create_table "spree_shipping_method_categories", id: :serial, force: :cascade do |t|
    t.bigint "shipping_method_id", null: false
    t.bigint "shipping_category_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["shipping_category_id", "shipping_method_id"], name: "unique_spree_shipping_method_categories", unique: true
    t.index ["shipping_category_id"], name: "index_spree_shipping_method_categories_on_shipping_category_id"
    t.index ["shipping_method_id"], name: "index_spree_shipping_method_categories_on_shipping_method_id"
  end

  create_table "spree_shipping_method_zones", id: :serial, force: :cascade do |t|
    t.bigint "shipping_method_id"
    t.bigint "zone_id"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.index ["shipping_method_id"], name: "index_spree_shipping_method_zones_on_shipping_method_id"
    t.index ["zone_id"], name: "index_spree_shipping_method_zones_on_zone_id"
  end

  create_table "spree_shipping_methods", id: :serial, force: :cascade do |t|
    t.string "name"
    t.string "display_on"
    t.datetime "deleted_at", precision: nil
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "tracking_url"
    t.string "admin_name"
    t.bigint "tax_category_id"
    t.string "code"
    t.integer "vendor_id"
    t.bigint "client_id"
    t.boolean "visible_to_vendors", default: false
    t.string "delivery_mode"
    t.integer "delivery_threshold"
    t.text "store_ids", default: [], array: true
    t.integer "cutt_off_time", default: 0
    t.boolean "lalamove_enabled", default: false
    t.string "lalamove_service_type", default: ""
    t.boolean "auto_schedule_lalamove", default: false
    t.boolean "hide_shipping_method", default: false
    t.boolean "scheduled_fulfilled", default: false
    t.integer "schedule_days_threshold", default: 365
    t.boolean "is_weighted", default: false
    t.jsonb "public_metadata"
    t.jsonb "private_metadata"
    t.index ["client_id"], name: "index_spree_shipping_methods_on_client_id"
    t.index ["deleted_at"], name: "index_spree_shipping_methods_on_deleted_at"
    t.index ["tax_category_id"], name: "index_spree_shipping_methods_on_tax_category_id"
    t.index ["vendor_id"], name: "index_spree_shipping_methods_on_vendor_id"
  end

  create_table "spree_shipping_rates", id: :serial, force: :cascade do |t|
    t.bigint "shipment_id"
    t.bigint "shipping_method_id"
    t.boolean "selected", default: false
    t.decimal "cost", precision: 16, scale: 2, default: "0.0"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "tax_rate_id"
    t.index ["selected"], name: "index_spree_shipping_rates_on_selected"
    t.index ["shipment_id", "shipping_method_id"], name: "spree_shipping_rates_join_index", unique: true
    t.index ["shipment_id"], name: "index_spree_shipping_rates_on_shipment_id"
    t.index ["shipping_method_id"], name: "index_spree_shipping_rates_on_shipping_method_id"
    t.index ["tax_rate_id"], name: "index_spree_shipping_rates_on_tax_rate_id"
  end

  create_table "spree_single_service_login", force: :cascade do |t|
    t.bigint "service_login_sub_admin_id", null: false
    t.bigint "client_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["client_id"], name: "index_spree_single_service_login_on_client_id"
    t.index ["service_login_sub_admin_id"], name: "index_spree_single_service_login_on_service_login_sub_admin_id"
  end

  create_table "spree_sitemaps", force: :cascade do |t|
    t.bigint "client_id"
    t.integer "file_count"
    t.string "invalid_store_ids"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "store_id"
    t.index ["client_id"], name: "index_spree_sitemaps_on_client_id"
  end

  create_table "spree_state_changes", id: :serial, force: :cascade do |t|
    t.string "name"
    t.string "previous_state"
    t.bigint "stateful_id"
    t.bigint "user_id"
    t.string "stateful_type"
    t.string "next_state"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["stateful_id", "stateful_type"], name: "index_spree_state_changes_on_stateful_id_and_stateful_type"
  end

  create_table "spree_states", id: :serial, force: :cascade do |t|
    t.string "name"
    t.string "abbr"
    t.bigint "country_id"
    t.datetime "updated_at", precision: nil
    t.bigint "client_id"
    t.datetime "created_at", precision: nil
    t.index ["client_id"], name: "index_spree_states_on_client_id"
    t.index ["country_id"], name: "index_spree_states_on_country_id"
  end

  create_table "spree_stock_items", id: :serial, force: :cascade do |t|
    t.bigint "stock_location_id"
    t.bigint "variant_id"
    t.integer "count_on_hand", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "backorderable", default: false
    t.datetime "deleted_at", precision: nil
    t.jsonb "public_metadata"
    t.jsonb "private_metadata"
    t.index "stock_location_id, variant_id, COALESCE(deleted_at, '1970-01-01 00:00:00'::timestamp without time zone)", name: "stock_item_by_loc_var_id_deleted_at", unique: true
    t.index ["backorderable"], name: "index_spree_stock_items_on_backorderable"
    t.index ["deleted_at"], name: "index_spree_stock_items_on_deleted_at"
    t.index ["stock_location_id", "variant_id"], name: "stock_item_by_loc_and_var_id"
    t.index ["stock_location_id"], name: "index_spree_stock_items_on_stock_location_id"
    t.index ["variant_id"], name: "index_spree_stock_items_on_variant_id"
  end

  create_table "spree_stock_locations", id: :serial, force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "default", default: false, null: false
    t.string "address1"
    t.string "address2"
    t.string "city"
    t.bigint "state_id"
    t.string "state_name"
    t.bigint "country_id"
    t.string "zipcode"
    t.string "phone"
    t.boolean "active", default: true
    t.boolean "backorderable_default", default: false
    t.boolean "propagate_all_variants", default: false
    t.string "admin_name"
    t.integer "vendor_id"
    t.bigint "client_id"
    t.index ["active"], name: "index_spree_stock_locations_on_active"
    t.index ["backorderable_default"], name: "index_spree_stock_locations_on_backorderable_default"
    t.index ["client_id"], name: "index_spree_stock_locations_on_client_id"
    t.index ["country_id"], name: "index_spree_stock_locations_on_country_id"
    t.index ["propagate_all_variants"], name: "index_spree_stock_locations_on_propagate_all_variants"
    t.index ["state_id"], name: "index_spree_stock_locations_on_state_id"
    t.index ["vendor_id"], name: "index_spree_stock_locations_on_vendor_id"
  end

  create_table "spree_stock_movements", id: :serial, force: :cascade do |t|
    t.bigint "stock_item_id"
    t.integer "quantity", default: 0
    t.string "action"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "originator_type"
    t.bigint "originator_id"
    t.index ["originator_id", "originator_type"], name: "index_stock_movements_on_originator_id_and_originator_type"
    t.index ["stock_item_id"], name: "index_spree_stock_movements_on_stock_item_id"
  end

  create_table "spree_stock_transfers", id: :serial, force: :cascade do |t|
    t.string "type"
    t.string "reference"
    t.bigint "source_location_id"
    t.bigint "destination_location_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "number"
    t.bigint "client_id"
    t.jsonb "public_metadata"
    t.jsonb "private_metadata"
    t.index ["client_id"], name: "index_spree_stock_transfers_on_client_id"
    t.index ["destination_location_id"], name: "index_spree_stock_transfers_on_destination_location_id"
    t.index ["number"], name: "index_spree_stock_transfers_on_number", unique: true
    t.index ["source_location_id"], name: "index_spree_stock_transfers_on_source_location_id"
  end

  create_table "spree_store_credit_categories", id: :serial, force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "client_id"
    t.index ["client_id"], name: "index_spree_store_credit_categories_on_client_id"
  end

  create_table "spree_store_credit_events", id: :serial, force: :cascade do |t|
    t.bigint "store_credit_id", null: false
    t.string "action", null: false
    t.decimal "amount", precision: 16, scale: 2
    t.string "authorization_code", null: false
    t.decimal "user_total_amount", precision: 16, scale: 2, default: "0.0", null: false
    t.bigint "originator_id"
    t.string "originator_type"
    t.datetime "deleted_at", precision: nil
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["originator_id", "originator_type"], name: "spree_store_credit_events_originator"
    t.index ["store_credit_id"], name: "index_spree_store_credit_events_on_store_credit_id"
  end

  create_table "spree_store_credit_types", id: :serial, force: :cascade do |t|
    t.string "name"
    t.integer "priority"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["priority"], name: "index_spree_store_credit_types_on_priority"
  end

  create_table "spree_store_credits", id: :serial, force: :cascade do |t|
    t.bigint "user_id"
    t.bigint "category_id"
    t.bigint "created_by_id"
    t.decimal "amount", precision: 16, scale: 2, default: "0.0", null: false
    t.decimal "amount_used", precision: 16, scale: 2, default: "0.0", null: false
    t.text "memo"
    t.datetime "deleted_at", precision: nil
    t.string "currency"
    t.decimal "amount_authorized", precision: 16, scale: 2, default: "0.0", null: false
    t.bigint "originator_id"
    t.string "originator_type"
    t.bigint "type_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "reason"
    t.string "type"
    t.string "transaction_id"
    t.decimal "balance", precision: 16, scale: 2, null: false
    t.integer "payment_mode"
    t.integer "transactioner_id"
    t.decimal "amount_remaining", precision: 16, scale: 2, default: "0.0"
    t.bigint "store_id"
    t.jsonb "public_metadata"
    t.jsonb "private_metadata"
    t.index ["deleted_at"], name: "index_spree_store_credits_on_deleted_at"
    t.index ["originator_id", "originator_type"], name: "spree_store_credits_originator"
    t.index ["store_id"], name: "index_spree_store_credits_on_store_id"
    t.index ["transaction_id"], name: "index_spree_store_credits_on_transaction_id", unique: true
    t.index ["transactioner_id"], name: "index_spree_store_credits_on_transactioner_id"
    t.index ["type"], name: "index_type_on_spree_store_credits"
    t.index ["type_id"], name: "index_spree_store_credits_on_type_id"
    t.index ["user_id"], name: "index_spree_store_credits_on_user_id"
    t.index ["user_id"], name: "index_user_id_on_spree_store_credits"
  end

  create_table "spree_store_payment_methods", id: :serial, force: :cascade do |t|
    t.integer "store_id"
    t.integer "payment_method_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "payment_option"
    t.string "payment_option_display"
    t.integer "apple_pay_domains", default: 1
    t.text "preferences"
  end

  create_table "spree_store_settings", force: :cascade do |t|
    t.text "preferences"
    t.bigint "store_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["store_id"], name: "index_spree_store_settings_on_store_id"
  end

  create_table "spree_store_shipping_methods", id: :serial, force: :cascade do |t|
    t.integer "store_id"
    t.integer "shipping_method_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["shipping_method_id"], name: "index_spree_store_shipping_methods_on_shipping_method_id"
    t.index ["store_id"], name: "index_spree_store_shipping_methods_on_store_id"
  end

  create_table "spree_store_translations", force: :cascade do |t|
    t.string "name"
    t.text "meta_description"
    t.text "meta_keywords"
    t.string "seo_title"
    t.string "facebook"
    t.string "twitter"
    t.string "instagram"
    t.string "customer_support_email"
    t.text "description"
    t.text "address"
    t.string "contact_phone"
    t.string "new_order_notifications_email"
    t.string "locale", null: false
    t.bigint "spree_store_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at", precision: nil
    t.index ["deleted_at"], name: "index_spree_store_translations_on_deleted_at"
    t.index ["locale"], name: "index_spree_store_translations_on_locale"
    t.index ["spree_store_id", "locale"], name: "index_spree_store_translations_on_spree_store_id_locale", unique: true
  end

  create_table "spree_stores", id: :serial, force: :cascade do |t|
    t.string "name"
    t.string "url"
    t.text "meta_description"
    t.text "meta_keywords"
    t.string "seo_title"
    t.string "mail_from_address"
    t.string "default_currency"
    t.string "code"
    t.boolean "default"
    t.timestamptz "created_at"
    t.datetime "updated_at", precision: nil
    t.string "logo_file_name"
    t.integer "magento_id"
    t.decimal "duty", precision: 16, scale: 2
    t.string "duty_currency"
    t.bigint "client_id"
    t.string "recipient_emails"
    t.boolean "google_translator", default: false
    t.boolean "ask_seller", default: false
    t.boolean "vendor_visibility", default: false
    t.boolean "mailchip", default: false
    t.text "custom_js", default: ""
    t.text "custom_css", default: ""
    t.text "gtm_tags", default: [], array: true
    t.string "fb_username", default: ""
    t.string "insta_username", default: ""
    t.string "twitter_username", default: ""
    t.string "pinterest_username", default: ""
    t.string "linkedin_username", default: ""
    t.text "description", default: ""
    t.string "recaptcha_key", default: ""
    t.boolean "country_specific", default: false
    t.text "page_title", default: ""
    t.string "subscription_title"
    t.text "subscription_text"
    t.string "copy_rights_text", default: ""
    t.boolean "top_category_url_to_product_listing", default: false
    t.float "carosel_spacing", default: 52.0
    t.integer "max_image_width", default: 600
    t.integer "max_image_height", default: 600
    t.string "app_fee_type", default: "percentage"
    t.integer "app_fee", default: 0
    t.integer "truncated_text_length"
    t.boolean "show_ship_countries", default: false
    t.string "adyen_origin_key", default: ""
    t.string "ship_to_label", default: ""
    t.text "bcc_emails", default: ""
    t.integer "per_page", default: 24
    t.boolean "download_order_details", default: false
    t.string "default_url"
    t.string "acm_arn", default: ""
    t.integer "default_tax_zone_id"
    t.boolean "enable_client_default_tax", default: false
    t.boolean "new_layout", default: false
    t.integer "pickup_address_id"
    t.text "swatches", default: [], array: true
    t.boolean "is_show_swatches", default: false
    t.boolean "store_curated", default: false
    t.boolean "enable_review_io", default: false
    t.string "reviews_io_api_key", default: ""
    t.string "reviews_io_store_id", default: ""
    t.string "reviews_io_bcc_email"
    t.string "invoice_company_name", default: ""
    t.text "invoice_company_address", default: ""
    t.string "invoice_company_reg_number", default: ""
    t.string "givex_url", default: ""
    t.string "givex_password", default: ""
    t.string "givex_user", default: ""
    t.string "supported_locale", default: "en"
    t.string "hawk_username", default: ""
    t.string "hawk_password", default: ""
    t.string "hawk_store_channel_code", default: ""
    t.string "hawk_api_url", default: ""
    t.string "ts_gift_card_email", default: ""
    t.string "ts_gift_card_password", default: ""
    t.boolean "enable_finance_report", default: false
    t.string "finance_report_to"
    t.string "finance_report_cc"
    t.integer "refunds_timeline", default: 14
    t.string "ts_gift_card_url"
    t.string "line_username", default: ""
    t.string "included_tax_label"
    t.string "excluded_tax_label"
    t.boolean "ses_emails", default: false
    t.string "stripe_standard_account_id"
    t.integer "decimal_points", default: 2
    t.boolean "currency_formatter", default: false
    t.boolean "enable_checkout_terms", default: false
    t.string "checkout_terms", default: ""
    t.boolean "enable_marketing", default: false
    t.string "marketing_statement", default: ""
    t.string "stripe_express_account_id"
    t.string "google_site_verification_tag", default: "hDqeXB6ba8wsabWbUUOuXUsu_5_tL-qU-TWGHWZM8QY"
    t.boolean "is_www_domain", default: false
    t.boolean "burger_menu_theme", default: false
    t.string "contact_number"
    t.string "mail_to"
    t.string "customer_service_url"
    t.string "lalamove_sk", default: ""
    t.string "lalamove_pk", default: ""
    t.string "lalamove_market", default: ""
    t.string "lalamove_url", default: ""
    t.string "sales_report_password"
    t.integer "schedule_report", default: 0
    t.integer "lalamove_pickup_order_tag_id"
    t.integer "lalamove_complete_order_tag_id"
    t.string "checkout_flow", default: "v1"
    t.float "min_custom_price", default: 0.0
    t.float "max_custom_price", default: 1000.0
    t.datetime "finance_report_generated_at", precision: nil
    t.float "max_cart_transaction"
    t.text "preferences"
    t.text "supported_currencies", default: [], array: true
    t.boolean "show_brand_name", default: false
    t.bigint "v3_flow_address_id"
    t.boolean "enable_v3_billing", default: false
    t.text "note"
    t.string "facebook"
    t.string "twitter"
    t.string "instagram"
    t.string "default_locale"
    t.string "customer_support_email"
    t.bigint "default_country_id"
    t.text "address"
    t.string "contact_phone"
    t.string "new_order_notifications_email"
    t.bigint "checkout_zone_id"
    t.string "seo_robots"
    t.string "supported_locales"
    t.date "fulfilment_start_date"
    t.boolean "allow_fulfilment", default: false
    t.datetime "deleted_at", precision: nil
    t.jsonb "settings"
    t.boolean "test_mode", default: true
    t.string "sabre_reference_code"
    t.string "hcaptcha_key", default: ""
    t.string "givex_secondary_url"
    t.string "prefix", default: ""
    t.string "suffix", default: ""
    t.index ["default_url"], name: "index_spree_stores_on_default_url"
    t.index ["deleted_at"], name: "index_spree_stores_on_deleted_at"
    t.index ["url", "default_url"], name: "index_spree_stores_on_url_and_default_url"
    t.index ["url"], name: "index_spree_stores_on_url"
  end

  create_table "spree_stores_zones", force: :cascade do |t|
    t.bigint "zone_id"
    t.bigint "store_id"
    t.index ["store_id"], name: "index_spree_stores_zones_on_store_id"
    t.index ["zone_id"], name: "index_spree_stores_zones_on_zone_id"
  end

  create_table "spree_subscriptions", force: :cascade do |t|
    t.string "email"
    t.string "status"
    t.string "list_id"
    t.string "subscriber_id"
    t.integer "user_id"
    t.bigint "store_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["store_id"], name: "index_spree_subscriptions_on_store_id"
  end

  create_table "spree_taggings", id: :serial, force: :cascade do |t|
    t.integer "tag_id"
    t.string "taggable_type"
    t.integer "taggable_id"
    t.string "tagger_type"
    t.integer "tagger_id"
    t.string "context", limit: 128
    t.datetime "created_at", precision: nil
    t.string "tenant", limit: 128
    t.index ["context"], name: "index_spree_taggings_on_context"
    t.index ["tag_id", "taggable_id", "taggable_type", "context", "tagger_id", "tagger_type"], name: "spree_taggings_idx", unique: true
    t.index ["tag_id"], name: "index_spree_taggings_on_tag_id"
    t.index ["taggable_id", "taggable_type", "tagger_id", "context"], name: "spree_taggings_idy"
    t.index ["taggable_id"], name: "index_spree_taggings_on_taggable_id"
    t.index ["taggable_type"], name: "index_spree_taggings_on_taggable_type"
    t.index ["tagger_id", "tagger_type"], name: "index_spree_taggings_on_tagger_id_and_tagger_type"
    t.index ["tagger_id"], name: "index_spree_taggings_on_tagger_id"
    t.index ["tenant"], name: "index_spree_taggings_on_tenant"
  end

  create_table "spree_tags", id: :serial, force: :cascade do |t|
    t.string "name"
    t.integer "taggings_count", default: 0
    t.integer "client_id"
    t.index ["client_id"], name: "index_spree_tags_on_client_id"
    t.index ["name", "client_id"], name: "index_spree_tags_on_name_and_client_id", unique: true
  end

  create_table "spree_tax_categories", id: :serial, force: :cascade do |t|
    t.string "name"
    t.string "description"
    t.boolean "is_default", default: false
    t.datetime "deleted_at", precision: nil
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "tax_code"
    t.bigint "client_id"
    t.index ["client_id"], name: "index_spree_tax_categories_on_client_id"
    t.index ["deleted_at"], name: "index_spree_tax_categories_on_deleted_at"
    t.index ["is_default"], name: "index_spree_tax_categories_on_is_default"
  end

  create_table "spree_tax_rates", id: :serial, force: :cascade do |t|
    t.decimal "amount", precision: 16, scale: 5
    t.bigint "zone_id"
    t.bigint "tax_category_id"
    t.boolean "included_in_price", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "name"
    t.boolean "show_rate_in_label", default: true
    t.datetime "deleted_at", precision: nil
    t.bigint "client_id"
    t.jsonb "public_metadata"
    t.jsonb "private_metadata"
    t.index ["client_id"], name: "index_spree_tax_rates_on_client_id"
    t.index ["deleted_at"], name: "index_spree_tax_rates_on_deleted_at"
    t.index ["included_in_price"], name: "index_spree_tax_rates_on_included_in_price"
    t.index ["show_rate_in_label"], name: "index_spree_tax_rates_on_show_rate_in_label"
    t.index ["tax_category_id"], name: "index_spree_tax_rates_on_tax_category_id"
    t.index ["zone_id"], name: "index_spree_tax_rates_on_zone_id"
  end

  create_table "spree_taxon_translations", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.string "locale", null: false
    t.bigint "spree_taxon_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "meta_title"
    t.string "meta_description"
    t.string "meta_keywords"
    t.string "permalink"
    t.index ["locale"], name: "index_spree_taxon_translations_on_locale"
    t.index ["spree_taxon_id", "locale"], name: "index_spree_taxon_translations_on_spree_taxon_id_and_locale", unique: true
  end

  create_table "spree_taxonomies", id: :serial, force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "position", default: 0
    t.integer "store_id"
    t.string "slug"
    t.bigint "client_id"
    t.integer "vendor_id"
    t.jsonb "public_metadata"
    t.jsonb "private_metadata"
    t.index ["client_id"], name: "index_spree_taxonomies_on_client_id"
    t.index ["position"], name: "index_spree_taxonomies_on_position"
    t.index ["store_id"], name: "index_spree_taxonomies_on_store_id"
  end

  create_table "spree_taxonomy_translations", force: :cascade do |t|
    t.string "name"
    t.string "locale", null: false
    t.bigint "spree_taxonomy_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["locale"], name: "index_spree_taxonomy_translations_on_locale"
    t.index ["spree_taxonomy_id", "locale"], name: "index_spree_taxonomy_translations_on_spree_taxonomy_id_locale", unique: true
  end

  create_table "spree_taxons", id: :serial, force: :cascade do |t|
    t.bigint "parent_id"
    t.integer "position", default: 0
    t.string "name"
    t.string "permalink"
    t.bigint "taxonomy_id"
    t.bigint "lft"
    t.bigint "rgt"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "meta_title"
    t.string "meta_description"
    t.string "meta_keywords"
    t.integer "depth"
    t.string "slug"
    t.integer "magento_id"
    t.bigint "client_id"
    t.boolean "hide_from_vendors", default: false
    t.integer "vendor_id"
    t.string "shopify_id"
    t.integer "banner_position"
    t.integer "attachment_id"
    t.text "banner_text"
    t.boolean "hide_from_nav", default: false
    t.jsonb "public_metadata"
    t.jsonb "private_metadata"
    t.index ["client_id"], name: "index_spree_taxons_on_client_id"
    t.index ["lft"], name: "index_spree_taxons_on_lft"
    t.index ["name", "parent_id", "taxonomy_id"], name: "index_spree_taxons_on_name_and_parent_id_and_taxonomy_id", unique: true
    t.index ["name"], name: "index_spree_taxons_on_name"
    t.index ["parent_id"], name: "index_taxons_on_parent_id"
    t.index ["permalink", "parent_id", "taxonomy_id"], name: "index_spree_taxons_on_permalink_and_parent_id_and_taxonomy_id", unique: true
    t.index ["permalink"], name: "index_taxons_on_permalink"
    t.index ["position"], name: "index_spree_taxons_on_position"
    t.index ["rgt"], name: "index_spree_taxons_on_rgt"
    t.index ["taxonomy_id"], name: "index_taxons_on_taxonomy_id"
  end

  create_table "spree_time_slots", force: :cascade do |t|
    t.float "interval"
    t.integer "shipping_method_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "start_time"
    t.string "end_time"
  end

  create_table "spree_trackers", id: :serial, force: :cascade do |t|
    t.string "analytics_id"
    t.boolean "active", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "engine", default: 0, null: false
    t.integer "store_id"
    t.index ["active"], name: "index_spree_trackers_on_active"
  end

  create_table "spree_ts_giftcards", force: :cascade do |t|
    t.string "number"
    t.string "customer_email"
    t.decimal "balance", precision: 16, scale: 2
    t.string "pin"
    t.integer "user_id"
    t.integer "line_item_id"
    t.integer "order_id"
    t.text "response"
    t.string "customer_first_name", default: ""
    t.string "customer_last_name", default: ""
    t.boolean "card_generated", default: false
    t.string "barcode_key"
    t.string "qrcode_key"
    t.string "slug"
    t.integer "store_id"
    t.integer "campaign_id"
    t.text "campaign_body"
    t.string "image_url"
    t.string "receipient_phone_number"
    t.boolean "bonus", default: false
    t.integer "send_gift_card_via", default: 1
    t.date "expiry_date"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.string "serial_number"
    t.integer "status", default: 0
    t.string "reference_number"
    t.integer "request_state", default: 0
    t.index ["reference_number"], name: "index_spree_ts_giftcards_on_reference_number", unique: true
    t.index ["slug"], name: "index_spree_ts_giftcards_on_slug", unique: true
  end

  create_table "spree_ts_pay_checkouts", force: :cascade do |t|
    t.string "cc_type"
    t.string "last_digits"
    t.string "gateway_payment_profile_id"
    t.integer "payment_method_id"
    t.integer "user_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "spree_users", id: :serial, force: :cascade do |t|
    t.string "encrypted_password", limit: 128
    t.string "password_salt", limit: 128
    t.string "email"
    t.string "remember_token"
    t.string "persistence_token"
    t.string "reset_password_token"
    t.string "perishable_token"
    t.integer "sign_in_count", default: 0, null: false
    t.integer "failed_attempts", default: 0, null: false
    t.datetime "last_request_at", precision: nil
    t.datetime "current_sign_in_at", precision: nil
    t.datetime "last_sign_in_at", precision: nil
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.string "login"
    t.bigint "ship_address_id"
    t.bigint "bill_address_id"
    t.string "authentication_token"
    t.string "unlock_token"
    t.datetime "locked_at", precision: nil
    t.datetime "reset_password_sent_at", precision: nil
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "spree_api_key", limit: 48
    t.datetime "remember_created_at", precision: nil
    t.datetime "deleted_at", precision: nil
    t.string "confirmation_token"
    t.datetime "confirmed_at", precision: nil
    t.datetime "confirmation_sent_at", precision: nil
    t.string "name"
    t.decimal "store_credits_total", precision: 16, scale: 2, default: "0.0"
    t.integer "magento_id"
    t.text "recent_product_ids", default: [], array: true
    t.boolean "news_letter", default: false
    t.bigint "client_id"
    t.integer "store_id"
    t.text "allow_store_ids", default: [], array: true
    t.text "allow_menu_items", default: ["Home", "Orders", "Products", "Gift Cards", "Conversations", "Vendors", "Stores", "Categories", "Gallery", "Settings"], array: true
    t.boolean "is_two_fa_enabled"
    t.boolean "enabled_marketing", default: false
    t.boolean "is_enabled", default: true
    t.boolean "is_v2_flow_enabled", default: false
    t.boolean "lead", default: false
    t.string "state", default: "createpayment"
    t.text "allow_campaign_ids", default: [], array: true
    t.boolean "fulfilment_user", default: false
    t.boolean "show_full_card_number", default: false
    t.jsonb "public_metadata"
    t.jsonb "private_metadata"
    t.string "first_name"
    t.string "last_name"
    t.string "selected_locale"
    t.string "user_report_password"
    t.boolean "is_iframe_user", default: false
    t.boolean "verified", default: false
    t.bigint "service_login_user_id"
    t.string "persona_type", default: "default"
    t.boolean "can_manage_sub_user", default: false
    t.index ["bill_address_id"], name: "index_spree_users_on_bill_address_id"
    t.index ["client_id"], name: "index_spree_users_on_client_id"
    t.index ["deleted_at"], name: "index_spree_users_on_deleted_at"
    t.index ["email", "client_id"], name: "index_spree_users_on_email_and_client_id", unique: true
    t.index ["ship_address_id"], name: "index_spree_users_on_ship_address_id"
    t.index ["spree_api_key"], name: "index_spree_users_on_spree_api_key"
  end

  create_table "spree_variants", id: :serial, force: :cascade do |t|
    t.string "sku", default: "", null: false
    t.decimal "weight", precision: 15, scale: 2, default: "0.0"
    t.decimal "height", precision: 8, scale: 2
    t.decimal "width", precision: 8, scale: 2
    t.decimal "depth", precision: 8, scale: 2
    t.datetime "deleted_at", precision: nil
    t.boolean "is_master", default: false
    t.bigint "product_id"
    t.decimal "cost_price", precision: 16, scale: 2
    t.integer "position"
    t.string "cost_currency"
    t.boolean "track_inventory", default: true
    t.bigint "tax_category_id"
    t.datetime "updated_at", precision: nil, null: false
    t.datetime "discontinue_on", precision: nil
    t.datetime "created_at", precision: nil, null: false
    t.integer "vendor_id"
    t.boolean "archived", default: false
    t.decimal "rrp", precision: 16, scale: 2
    t.string "shopify_id"
    t.string "shopify_product_id"
    t.integer "parent_variant_id"
    t.bigint "linked_inventory_id"
    t.string "placeholder"
    t.decimal "unit_cost_price", precision: 10, scale: 2, default: "0.0"
    t.string "barcode_number", default: ""
    t.jsonb "public_metadata"
    t.jsonb "private_metadata"
    t.string "barcode"
    t.index ["barcode"], name: "index_spree_variants_on_barcode"
    t.index ["deleted_at"], name: "index_spree_variants_on_deleted_at"
    t.index ["discontinue_on"], name: "index_spree_variants_on_discontinue_on"
    t.index ["is_master"], name: "index_spree_variants_on_is_master"
    t.index ["position"], name: "index_spree_variants_on_position"
    t.index ["product_id"], name: "index_spree_variants_on_product_id"
    t.index ["sku"], name: "index_spree_variants_on_sku"
    t.index ["tax_category_id"], name: "index_spree_variants_on_tax_category_id"
    t.index ["track_inventory"], name: "index_spree_variants_on_track_inventory"
    t.index ["vendor_id"], name: "index_spree_variants_on_vendor_id"
  end

  create_table "spree_vendor_groups", force: :cascade do |t|
    t.datetime "deleted_at", precision: nil
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "spree_vendor_sale_analyses", force: :cascade do |t|
    t.string "number"
    t.string "storefront"
    t.datetime "completed_at", precision: nil
    t.string "status"
    t.string "email"
    t.string "currency"
    t.string "delivery_pickup_date"
    t.string "delivery_pickup_time"
    t.string "shipped_date"
    t.string "shipped_time"
    t.decimal "tax_inclusive"
    t.decimal "additional_tax"
    t.string "tags"
    t.decimal "total"
    t.integer "vendor_id"
    t.integer "order_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["completed_at"], name: "index_spree_vendor_sale_analyses_on_completed_at"
    t.index ["email"], name: "index_spree_vendor_sale_analyses_on_email"
    t.index ["number"], name: "index_spree_vendor_sale_analyses_on_number"
    t.index ["storefront"], name: "index_spree_vendor_sale_analyses_on_storefront"
  end

  create_table "spree_vendor_translations", force: :cascade do |t|
    t.string "name"
    t.text "about_us"
    t.text "contact_us"
    t.string "slug"
    t.string "locale", null: false
    t.bigint "spree_vendor_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["locale"], name: "index_spree_vendor_translations_on_locale"
    t.index ["spree_vendor_id", "locale"], name: "unique_vendor_id_per_locale", unique: true
  end

  create_table "spree_vendor_users", id: :serial, force: :cascade do |t|
    t.integer "vendor_id"
    t.integer "user_id"
    t.index ["user_id"], name: "index_spree_vendor_users_on_user_id"
    t.index ["vendor_id", "user_id"], name: "index_spree_vendor_users_on_vendor_id_and_user_id", unique: true
    t.index ["vendor_id"], name: "index_spree_vendor_users_on_vendor_id"
  end

  create_table "spree_vendors", id: :serial, force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.string "state"
    t.datetime "deleted_at", precision: nil
    t.string "slug"
    t.text "about_us"
    t.text "contact_us"
    t.string "email"
    t.string "contact_name"
    t.boolean "enabled"
    t.boolean "page_enabled"
    t.string "phone"
    t.boolean "vacation_mode"
    t.datetime "vacation_start", precision: nil
    t.datetime "vacation_end", precision: nil
    t.integer "bill_address_id"
    t.integer "ship_address_id"
    t.string "conf_contact_name"
    t.string "banner_image"
    t.string "landing_page_title"
    t.string "enabled_google_analytics"
    t.string "google_analytics_account_number"
    t.text "description"
    t.string "sku"
    t.integer "banner_image_id"
    t.integer "image_id"
    t.integer "magento_id"
    t.string "landing_page_url"
    t.text "additional_emails"
    t.bigint "client_id"
    t.text "designer_text", default: ""
    t.boolean "microsite", default: true
    t.boolean "dashboard_shipping", default: false
    t.text "local_store_ids", default: [], array: true
    t.boolean "master", default: false
    t.decimal "mov", precision: 16, scale: 2
    t.string "sales_report_password"
    t.bigint "vendor_group_id"
    t.boolean "agreed_to_client_terms", default: false
    t.boolean "external_vendor", default: false
    t.index ["client_id"], name: "index_spree_vendors_on_client_id"
    t.index ["deleted_at"], name: "index_spree_vendors_on_deleted_at"
    t.index ["slug"], name: "index_spree_vendors_on_slug", unique: true
    t.index ["state"], name: "index_spree_vendors_on_state"
    t.index ["vacation_end"], name: "index_spree_vendors_on_vacation_end"
    t.index ["vacation_start"], name: "index_spree_vendors_on_vacation_start"
  end

  create_table "spree_webhooks_events", force: :cascade do |t|
    t.integer "execution_time"
    t.string "name", null: false
    t.string "request_errors"
    t.string "response_code"
    t.bigint "subscriber_id", null: false
    t.boolean "success"
    t.string "url", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["response_code"], name: "index_spree_webhooks_events_on_response_code"
    t.index ["subscriber_id"], name: "index_spree_webhooks_events_on_subscriber_id"
    t.index ["success"], name: "index_spree_webhooks_events_on_success"
  end

  create_table "spree_webhooks_subscribers", force: :cascade do |t|
    t.string "url", null: false
    t.boolean "active", default: false
    t.jsonb "subscriptions"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "secret_key", null: false
    t.index ["active"], name: "index_spree_webhooks_subscribers_on_active"
  end

  create_table "spree_weights", force: :cascade do |t|
    t.decimal "maximum", precision: 15, scale: 2, default: "0.0"
    t.decimal "minimum", precision: 15, scale: 2, default: "0.0"
    t.float "price", default: 0.0
    t.string "weightable_type"
    t.bigint "weightable_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["weightable_type", "weightable_id"], name: "index_spree_weights_on_weightable_type_and_weightable_id"
  end

  create_table "spree_whitelist_emails", force: :cascade do |t|
    t.string "email"
    t.bigint "client_id"
    t.integer "status", default: 0
    t.boolean "verification_sent", default: false
    t.integer "user_id", null: false
    t.string "service_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "identity_type", default: 0
    t.string "domain", default: ""
    t.string "recipient_email", default: ""
    t.jsonb "meta", default: {}
    t.index ["client_id"], name: "index_spree_whitelist_emails_on_client_id"
  end

  create_table "spree_wished_items", id: :serial, force: :cascade do |t|
    t.bigint "variant_id"
    t.bigint "wishlist_id"
    t.text "remark"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "quantity", default: 1, null: false
    t.index ["variant_id", "wishlist_id"], name: "index_spree_wished_items_on_variant_id_and_wishlist_id", unique: true
    t.index ["variant_id"], name: "index_spree_wished_items_on_variant_id"
    t.index ["wishlist_id"], name: "index_spree_wished_items_on_wishlist_id"
  end

  create_table "spree_wishlists", id: :serial, force: :cascade do |t|
    t.bigint "user_id"
    t.string "name"
    t.string "token"
    t.boolean "is_private", default: true, null: false
    t.boolean "is_default", default: false, null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.bigint "store_id"
    t.index ["store_id"], name: "index_spree_wishlists_on_store_id"
    t.index ["token"], name: "index_spree_wishlists_on_token", unique: true
    t.index ["user_id", "is_default"], name: "index_spree_wishlists_on_user_id_and_is_default"
    t.index ["user_id"], name: "index_spree_wishlists_on_user_id"
  end

  create_table "spree_zone_members", id: :serial, force: :cascade do |t|
    t.string "zoneable_type"
    t.bigint "zoneable_id"
    t.bigint "zone_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["zone_id"], name: "index_spree_zone_members_on_zone_id"
    t.index ["zoneable_id", "zoneable_type"], name: "index_spree_zone_members_on_zoneable_id_and_zoneable_type"
  end

  create_table "spree_zones", id: :serial, force: :cascade do |t|
    t.string "name"
    t.string "description"
    t.boolean "default_tax", default: false
    t.integer "zone_members_count", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "kind"
    t.bigint "client_id"
    t.boolean "fulfilment_zone", default: false
    t.string "zone_code"
    t.bigint "creator_id"
    t.index ["client_id"], name: "index_spree_zones_on_client_id"
    t.index ["default_tax"], name: "index_spree_zones_on_default_tax"
    t.index ["kind"], name: "index_spree_zones_on_kind"
  end

  create_table "taggings", force: :cascade do |t|
    t.bigint "tag_id"
    t.string "taggable_type"
    t.bigint "taggable_id"
    t.string "tagger_type"
    t.bigint "tagger_id"
    t.string "context", limit: 128
    t.datetime "created_at", precision: nil
    t.index ["context"], name: "index_taggings_on_context"
    t.index ["tag_id", "taggable_id", "taggable_type", "context", "tagger_id", "tagger_type"], name: "taggings_idx", unique: true
    t.index ["tag_id"], name: "index_taggings_on_tag_id"
    t.index ["taggable_id", "taggable_type", "context"], name: "taggings_taggable_context_idx"
    t.index ["taggable_id", "taggable_type", "tagger_id", "context"], name: "taggings_idy"
    t.index ["taggable_id"], name: "index_taggings_on_taggable_id"
    t.index ["taggable_type", "taggable_id"], name: "index_taggings_on_taggable_type_and_taggable_id"
    t.index ["taggable_type"], name: "index_taggings_on_taggable_type"
    t.index ["tagger_id", "tagger_type"], name: "index_taggings_on_tagger_id_and_tagger_type"
    t.index ["tagger_id"], name: "index_taggings_on_tagger_id"
    t.index ["tagger_type", "tagger_id"], name: "index_taggings_on_tagger_type_and_tagger_id"
  end

  create_table "tags", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "taggings_count", default: 0
    t.integer "client_id"
    t.index ["name"], name: "index_tags_on_name", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "history_logs", "spree_users", column: "creator_id"
  add_foreign_key "order_error_logs", "spree_line_items", column: "line_item_id"
  add_foreign_key "order_error_logs", "spree_orders", column: "order_id"
  add_foreign_key "spree_aws_files", "spree_users", column: "created_by_id"
  add_foreign_key "spree_clients_service_login", "spree_clients", column: "client_id"
  add_foreign_key "spree_clients_service_login", "spree_users", column: "service_login_sub_admin_id"
  add_foreign_key "spree_oauth_access_grants", "spree_oauth_applications", column: "application_id"
  add_foreign_key "spree_oauth_access_tokens", "spree_oauth_applications", column: "application_id"
  add_foreign_key "spree_option_type_translations", "spree_option_types"
  add_foreign_key "spree_option_value_translations", "spree_option_values"
  add_foreign_key "spree_payment_sources", "spree_payment_methods", column: "payment_method_id"
  add_foreign_key "spree_payment_sources", "spree_users", column: "user_id"
  add_foreign_key "spree_product_property_translations", "spree_product_properties"
  add_foreign_key "spree_product_translations", "spree_products"
  add_foreign_key "spree_property_translations", "spree_properties"
  add_foreign_key "spree_single_service_login", "spree_clients", column: "client_id"
  add_foreign_key "spree_single_service_login", "spree_users", column: "service_login_sub_admin_id"
  add_foreign_key "spree_store_translations", "spree_stores"
  add_foreign_key "spree_taxon_translations", "spree_taxons"
  add_foreign_key "spree_taxonomy_translations", "spree_taxonomies"
  add_foreign_key "spree_vendor_translations", "spree_vendors"
  add_foreign_key "taggings", "tags"
end
