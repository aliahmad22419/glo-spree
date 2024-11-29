Ransack.configure do |config|
  config.add_predicate 'order_comp_date_between',
                       arel_predicate: 'order_comp_date_between',
                       formatter: proc { |v| v.to_date },
                       validator: proc { |v| v.present? },
                       type: :string
end

module Arel
  module Predications
    def order_comp_date_between date
      gteq(date.to_date.beginning_of_day).and(lt(date.end_of_day))
    end
  end
end