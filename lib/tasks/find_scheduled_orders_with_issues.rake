$orders_with_issues = []
namespace :orders do
  desc "Find scheduled orders with issues"
  task :find_scheduled_orders_with_issues => :environment do
    begin
      STDOUT.puts "Enter start date in this format YYYY-MM-DD "
      start_date = STDIN.gets.strip
      STDOUT.puts "Enter end date in this format YYYY-MM-DD "
      end_date = STDIN.gets.strip

      if !valid_date?(start_date) || !valid_date?(end_date)
        STDOUT.puts "Invalid dates, Please try again with valid dates."
      else
        start_time = Time.parse(start_date).beginning_of_day
        end_time = Time.parse(end_date).end_of_day
        STDOUT.puts "Processing..."
        find_orders_with_issues(start_time, end_time)
      end

    rescue Exception => e
      puts e.message
      Rails.logger.error(e.message)
    end
  end

  def valid_date?(date)
    begin
      parsed_date = Date.parse(date)
      return true
    rescue Exception=>e
      return false
    end
  end


  def notify_shipments_if_issue(order)
    count_is, count_should_be = order.shipment_count_should_be
    return count_should_be.eql?(count_is)
  end

  def notify_givex_ts_cards_if_issue(digital_line)
      order = digital_line.order
      bonus_card = digital_line.eligible_bonus_card_promo
      
      quantity_is, quantity_should_be = digital_line.givex_cards.is_generated.count, digital_line.quantity
      quantity_should_be = quantity_should_be * 2 if bonus_card
      if digital_line.delivery_mode.include?('givex_digital') && quantity_is != quantity_should_be
          $orders_with_issues.push({order_number: "#{order.number}", issue: "Givex digital cards required quantity is not generated."})
          return true
      end 
      
      quantity_is, quantity_should_be = digital_line.ts_giftcards.is_generated.count, digital_line.quantity
      quantity_should_be = quantity_should_be * 2 if bonus_card && digital_line.product.ts_type.eql?("monetary")
      if digital_line.delivery_mode.include?('tsgift_digital') && quantity_is != quantity_should_be
          $orders_with_issues.push({order_number: "#{order.number}", issue: "TSgift digital cards required quantity is not generated."})
          return true
      end 
  end

  def find_orders_with_issues(start_time, end_time)
    
    order_ids = missed_shipments = missed_cards = []
    selected_orders = Spree::Order.complete.where(spree_orders: {completed_at: start_time..end_time}).distinct
    
    selected_orders.each do |order|
        count = count+1 if order_ids.include?(order.number)
        order_ids.push(order.number)

        unless notify_shipments_if_issue(order)
            missed_shipments.push(order.number)
            $orders_with_issues.push({order_number: "#{order.number}", issue: "Missing Shipments"})
        end 
        order.shipments.gift_card_shipments.each do |shipment|
            next if shipment.shipping_method.scheduled_fulfilled && shipment.card_generation_datetime&.future?
            if notify_givex_ts_cards_if_issue(shipment.line_items.first)
              missed_cards.push(shipment.order.number)
            end
        end
    end


    folder = "./public/scheduled"
    Dir.mkdir(folder) unless File.exists?(folder)

    file_path = "./public/scheduled/orders-with-issues-#{Time.now.to_s.parameterize}.csv"
    CSV.open(file_path, "wb") do |csv|
        csv << ["Order Number", "Issue"]
        
        $orders_with_issues.each do |issue|
            csv << [issue[:order_number], issue[:issue]]
        end
    end

    puts "Task is completed."
    puts "Report path: #{file_path}"
    Rails.logger.info("Order Number => Missing shipments: #{missed_shipments.uniq}\nMissing cards: #{missed_cards.uniq}")
  end

end
