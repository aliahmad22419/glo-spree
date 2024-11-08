# This class should be refactored
module Spree
  class CompareLineItems
    prepend Spree::ServiceModule:: Base

    def call(order:, line_item:, options: {}, comparison_hooks: Rails.application.config.spree.line_item_comparison_hooks)
      legacy_part = comparison_hooks.all? do |hook|
        order.send(hook, line_item, options)
      end

      success(legacy_part && compare(line_item, options))
    end

    private

    #gift type line items wont be merged/matched
    def compare(line_item, options)
      line_item&.product_type != "gift" ? compare_by_customizations(line_item, options) : false
    end

    def compare_by_customizations(line_item, options)
      matching_customizations = []
      options_customizations = options[:customization_options] || []
      customizations = line_item.line_item_customizations

      return false unless customizations.count == options_customizations.count

      options_customizations.each do |opt|
        match_found = line_item.line_item_customizations.find_by(customization_option_id: opt[:customization_option_id], value: opt[:value])
        break if match_found.blank?
        matching_customizations << match_found
      end

      matching_customizations.count == options_customizations.count
    end

  end
end
