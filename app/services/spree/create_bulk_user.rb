module Spree
  class CreateBulkUser
    CSV_HEADERS = ["Name", "Email", "Password", "Role", "V2 flow", "Enable 2FA", "Enable Access", "Persona/Group"]

    def initialize(file, current_client, current_user)
      @current_user = current_user
      @file = file
      @current_client = current_client
      @campaign = begin
        set_ts_campaign
      rescue => exception
        Rails.logger.error(exception.message)
        {}
      end
    end

    def call
      if @current_user.has_spree_role?('sub_client') && !@current_user.can_manage_sub_user
        return 'you are not allowed to import sub users.'
      end
      csv_data = CSV.read(@file.path, headers: true)
      error_message = ""

      Spree::User.transaction do
        csv_data.each do |row|
          next if row["Name"].blank? && row["Email"].blank? && row["Role"].blank?
          role = row["Role"]

          if Spree::XssValidationConcern.forbidden_tag_exist? row.to_s
            return "Forbidden Entity"
          elsif role.downcase == "redemption"
            error_message = create_redemption_user(row, csv_data.headers)
          elsif role.downcase == "sub-user" && row["Persona/Group"].present?
            error_message = create_sub_client_user(row, csv_data.headers)
          end
          break if error_message.present?
        end
        raise ActiveRecord::Rollback if error_message.present?
      end

      error_message
      rescue ActiveRecord::RecordNotUnique => e
        error_message = "Email has already been taken"
    end

    private

    def create_redemption_user(row, headers)
      user = @current_client.users.new(
        name: row["Name"],
        email: row["Email"],
        password: row["Password"],
        is_v2_flow_enabled: row["V2 flow"].to_s.downcase == "true",
        is_two_fa_enabled: row["Enable 2FA"].to_s.downcase == "true",
        is_enabled: row["Enable Access"].to_s.downcase == "true",
        state: "completed"
      )
      error_message = user.validate_user(headers - ["Persona/Group", 'Can Create Sub User'], row["Role"])
      if error_message.blank?
        user.spree_roles << Spree::Role.find_by_name(:front_desk)
        if user.save
          user.generate_spree_api_key!
        else
          error_message = "#{user.errors.full_messages.join(', ')}"
        end
      end
      error_message.present? ? error_message : nil
    end

    def create_sub_client_user(row, headers)
      persona_mapping = {
        'admin' => 'admin',
        'editor' => 'editor',
        'fulfilment' => 'fulfilment'
      }

      return nil unless persona_mapping[row["Persona/Group"].to_s.downcase].present?
      user_hash = {
        name: row["Name"],
        email: row["Email"],
        password: row["Password"],
        is_v2_flow_enabled: row["V2 flow"].to_s.downcase == "true",
        is_two_fa_enabled: row["Enable 2FA"].to_s.downcase == "true",
        is_enabled: row["Enable Access"].to_s.downcase == "true",
        persona_type: row["Persona/Group"].downcase,
        state: "completed"
      }
      user_hash[:can_manage_sub_user] = row['Can Create Sub User'].to_s.downcase == "true" if @current_user.has_spree_role?("client")
      user = @current_client.users.new(user_hash)
      error_message = validate_sub_client_user(user, headers, row["Role"])
      if error_message.blank?
        user.spree_roles << Spree::Role.find_by_name(:sub_client)
        assign_persona(user)

        if user.save
          set_menu_item_users_visiblty(user)
          user.generate_spree_api_key!
        else
          error_message = "#{user.errors.full_messages.join(', ')}"
        end
      end
      error_message.present? ? error_message : nil
    end

    def validate_sub_client_user(user, headers, role)
      client_csv_headers = CSV_HEADERS.dup.insert(-2, 'Can Create Sub User')
      return "Invalid CSV file." if (@current_user.has_spree_role?('client') && headers != client_csv_headers) || (@current_user.has_spree_role?('sub_client') && headers != CSV_HEADERS)
      return "Invalid email format" unless user.email.match?(/\A[\w+\-.]+@[a-z\d\-]+(\.[a-z]+)*\.[a-z]+\z/i)
    end

    def assign_persona(user)
      persona = @current_client.personas.find_by(persona_code: user.persona_type)

      user.allow_store_ids = persona.store_ids
      user.menu_item_ids = persona.menu_item_ids
      user.allow_campaign_ids = @campaign.pluck("id") rescue []
    end

    def set_ts_campaign
      auth = {username: @current_client.ts_email, password: @current_client.ts_password}
      ts_url = @current_client.ts_url
      result = HTTParty.get("#{ts_url}/api/v1/campaigns", basic_auth: auth)
      return result["campaigns"]
    end

    def set_menu_item_users_visiblty(user)
      user.menu_item_users.each do |item|
        item.update(visible: item.menu_item.visible)
      end
    end
  end
end
