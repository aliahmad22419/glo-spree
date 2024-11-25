module Spree
    module EnsureLineItemVendorConcern 
        def self.included(base)
            base.class_eval do
                private
                    def raise_if_product_vendor_changed
                        if spree_current_order&.line_items&.any?{|item| item.variant.vendor_id != item.vendor_id }
                            spree_current_order.line_items.destroy_all
                            render_error_payload(failure(spree_current_order, Spree.t(:product_vendor_changed_error)).error, 409) and return
                        end
                    end
            end
        end
    end
end
