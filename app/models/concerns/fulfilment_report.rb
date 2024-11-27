module FulfilmentReport
  attr_accessor :file_path, :password
  class << self
    def to_csv(options = {})
      ppi_headers = ['Store Name', 'Fulfilment Date', 'Order Date', 'Exec', 'Fulfilment Zone', 'Order Number',
                     'Serial Number', 'Gift Card Number', 'Gift Card Currency', 'Individual Gift Card Value', 'Gift Card Quantity',
                     'Total Gift Card Value', 'Currency (Shipping Paid)', 'Shipping Paid', 'Currency (Postage Paid)',
                     'Postage fee/type', 'Receipt Number', 'Courier', 'Tracking Details', 'Replacement', 'Charge to who',
                     'Additional Comments']
      headers = ppi_headers

      CSV.open("#{@file_path}.csv", 'wb') do |csv|
        csv << headers
        fulfilment_infos = options[:fulfilment_infos]
        fulfilment_infos.each { |fulfilment_info| generate_fulfilment_row(options, csv, fulfilment_info) }
      end
    end

    def download_csv(options = {})
      fulfilment_infos, user, method_name, filename = options[:fulfilment_infos], options[:user], options[:method], options[:filename]
      return if user.blank? || method_name.blank?

      reports_path = "public/user-reports"
      Dir.mkdir("#{reports_path}") unless Dir.exist?("#{reports_path}")
      reports_path = "#{reports_path}/fulfil_user_#{user.id}"
      Dir.mkdir("#{reports_path}") unless Dir.exist?("#{reports_path}")
      FileUtils.rm_rf(Dir["#{reports_path}/*"])

      @file_path = "#{reports_path}/#{filename}"

      self.send(method_name, {fulfilment_infos: fulfilment_infos, current_user: user})

      @password = (user&.user_report_password || ENV['ZIP_ENCRYPTION'])

      Spree::Order.add_to_zip(@file_path, @password)
      "#{@file_path}.zip"
    end

    private

    def generate_fulfilment_row(options, csv, fulfilment_info)
      masked_number = %w[fulfilment_admin].include?(options[:current_user].spree_roles.first.name) if options[:current_user].present?

      gift_card_number = fulfilment_info&.gift_card_number
      if masked_number
        gift_card_number = gift_card_number.split(',').map { |gift_card|
          gift_card.length >= 6 ? gift_card&.gsub(/.(?=.{4})/, '*') : gift_card&.gsub(/.(?=.{2})/, '*')
        }.join(',')
      end

      column_values = {
          'Store Name' => fulfilment_info&.shipment&.order&.store&.name,
          'Fulfilment Date' => fulfilment_info&.processed_date,
          'Order Date' => fulfilment_info&.shipment&.order&.completed_at,
          'Exec' => fulfilment_info&.user&.name,
          'Fulfilment Zone' => fulfilment_info&.shipment&.order&.zone&.name,
          'Order Number' => fulfilment_info&.shipment&.order&.number,
          'Serial Number' => fulfilment_info&.serial_number,
          'Gift Card Number' => gift_card_number,
          'Gift Card Currency' => fulfilment_info&.currency,
          'Individual Gift Card Value' => fulfilment_info&.each_card_value,
          'Gift Card Quantity' => fulfilment_info&.quantity,
          'Total Gift Card Value' => fulfilment_info&.amount.to_f,
          'Currency (Shipping Paid)' => fulfilment_info&.currency,
          'Shipping Paid' => fulfilment_info&.customer_shippment_paid.to_f,
          'Currency (Postage Paid)' => fulfilment_info&.postage_currency,
          'Postage fee/type' => fulfilment_info&.postage_fee.to_f,
          'Receipt Number' => fulfilment_info&.receipt_reference,
          'Courier' => fulfilment_info&.courier_company,
          'Tracking Details' => fulfilment_info&.tracking_number,
          'Replacement' => (fulfilment_info&.replacement? ? 'YES' : 'NO'),
          'Charge to who' => fulfilment_info&.replacement_info&.[]("charged_by") || 'N/A',
          'Additional Comments' => fulfilment_info&.comment
      }

      values = column_values.values
      csv << values
    end

  end
end
