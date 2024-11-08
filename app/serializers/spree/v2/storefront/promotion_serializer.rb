module Spree
  module V2
    module Storefront
      class PromotionSerializer < BaseSerializer
        set_type :promotion

        attributes :name, :description, :expires_at, :starts_at, :type, :usage_limit,
        :match_policy, :code, :advertise, :path, :credits_count

        attribute :promotion_category_id do |object|
          object.promotion_category_id.to_s
        end

        attribute :expires_at do |object|
          object.expires_at.strftime("%B %d, %Y") rescue nil
        end

        attribute :users do |object|
          Spree::User.where(store_id: object.client.stores.ids).joins(:spree_roles).where(spree_roles: { name: 'customer' }).order("spree_users.email ASC").uniq {|user| user.email}
        end

        attribute :taxons do |object|
          object.client.taxons.order("spree_taxons.permalink ASC")
                .map{|taxon| {id: taxon.id, permalink: taxon.permalink, vendor: taxon.vendor.try(:name)}}
        end

        attribute :products do |object|
          object.client.products.order(name: :asc).pluck(:id, :name).map { |id, name| {id: id, name: name} }
        end

        attribute :stores do |object|
          object.client.stores.where("stripe_standard_account_id IS NOT NULL AND stripe_standard_account_id != '' OR
                                        stripe_express_account_id IS NOT NULL AND stripe_express_account_id != ''")
                               .order(name: :asc).pluck(:id, :name).map { |id, name| {id: id, name: name} }
        end

        attribute :variants do |object|
          variants = []
          products = object.client.products
          products.each do |product|
            if product.variants.present?
             product.variants.each{|var|  variants << var.attributes.slice('id', 'sku')}
            end
          end
          variants.sort_by! {|h| h['sku']}
        end

        attribute :promotion_rule_names do |object|
          existing = object.rules.map { |rule| rule.class.name }
          rule_names = Rails.application.config.spree.promotions.rules.map(&:name).reject { |r| existing.include? r }
          rule_names.delete("Spree::Promotion::Rules::OptionValue")
          rule_names.delete("Spree::Promotion::Rules::UserLoggedIn")
          rule_names.map { |name| [Spree.t("promotion_rule_types.#{name.demodulize.underscore}.name"), name] }
        end

        attribute :promotion_rules do |object|
          Spree::V2::Storefront::PromotionRuleSerializer.new(object.promotion_rules).serializable_hash
        end

        attribute :promotion_actions do |object|
          Spree::V2::Storefront::PromotionActionSerializer.new(object.promotion_actions).serializable_hash
        end

        attribute :line_item_types do |object|
          Spree::LineItem.class_eval{ PRODUCT_TYPES }
        end
      end
    end
  end
end
