
# Following changes are related to latest version of acts_as_taggable_on gem
# If we update acts_as_taggable_on gem we will have to update the spree core gem
# and it can break changes. So thats why i have just picked only tenant related changes and put them in this file to support tenant based feature.

gem_dir = Gem::Specification.find_by_name("acts-as-taggable-on").gem_dir
require "#{gem_dir}/lib/acts-as-taggable-on/taggable/core"

ActsAsTaggableOn::Tag.class_eval do

#   def self.tenant_based(tenant_id)
#     where("spree_tags.client_id=?", tenant_id)
#   end

#   def self.find_or_create_all_with_like_by_name(*list, tenant_id)
#     list = Array(list).flatten

#     return [] if list.empty?

#     list.map do |tag_name|
#       begin
#         tries ||= 3

#         existing_tags = named_any(list)
#         existing_tags = named_any(list).tenant_based(tenant_id) if tenant_id.present?
#         comparable_tag_name = comparable_name(tag_name)
#         existing_tag = existing_tags.find { |tag| comparable_name(tag.name) == comparable_tag_name }
#         existing_tag || create(name: tag_name)
#       rescue ActiveRecord::RecordNotUnique
#         if (tries -= 1).positive?
#           ActiveRecord::Base.connection.execute 'ROLLBACK'
#           retry
#         end

#         raise DuplicateTagError.new("'#{tag_name}' has already been taken")
#       end
#     end
#   end

# end

# ActsAsTaggableOn::Taggable::Core.module_eval do

#   def taggable_tenant
#     public_send(self.class.tenant_column) if self.class.tenant_column
#   end

#   # Find existing tags or create non-existing tags
#   def load_tags(tag_list)
#     ActsAsTaggableOn::Tag.find_or_create_all_with_like_by_name(tag_list,taggable_tenant)
#   end

#   def save_tags
#     tagging_contexts.each do |context|
#       next unless tag_list_cache_set_on(context)
#       # List of currently assigned tag names
#       tag_list = tag_list_cache_on(context).uniq

#       # Find existing tags or create non-existing tags:
#       tags = find_or_create_tags_from_list_with_context(tag_list, context)

#       # Tag objects for currently assigned tags
#       current_tags = tags_on(context)

#       # Tag maintenance based on whether preserving the created order of tags
#       if self.class.preserve_tag_order?
#         old_tags, new_tags = current_tags - tags, tags - current_tags

#         shared_tags = current_tags & tags

#         if shared_tags.any? && tags[0...shared_tags.size] != shared_tags
#           index = shared_tags.each_with_index { |_, i| break i unless shared_tags[i] == tags[i] }

#           # Update arrays of tag objects
#           old_tags |= current_tags[index...current_tags.size]
#           new_tags |= current_tags[index...current_tags.size] & shared_tags

#           # Order the array of tag objects to match the tag list
#           new_tags = tags.map do |t|
#             new_tags.find { |n| n.name.downcase == t.name.downcase }
#           end.compact
#         end
#       else
#         # Delete discarded tags and create new tags
#         old_tags = current_tags - tags
#         new_tags = tags - current_tags
#       end

#       # Destroy old taggings:
#       if old_tags.present?
#         taggings.not_owned.by_context(context).where(tag_id: old_tags).destroy_all
#       end

#       # Create new taggings:
#       new_tags.each do |tag|
#         if taggable_tenant
#           taggings.create!(tag_id: tag.id, context: context.to_s, taggable: self, tenant: taggable_tenant)
#         else
#           taggings.create!(tag_id: tag.id, context: context.to_s, taggable: self)
#         end
#       end
#     end

#     true
#   end
# end

# module ActsAsTaggableOn
#   module Taggable

#     def acts_as_taggable_tenant(tenant)
#       if taggable?
#       else
#         class_attribute :tenant_column
#       end
#       self.tenant_column = tenant

#       # each of these add context-specific methods and must be
#       # called on each call of taggable_on
#       include Core
#       include Collection
#       include Cache
#       include Ownership
#       include Related
#     end

#     private

#     def taggable_on(preserve_tag_order, *tag_types)
#       tag_types = tag_types.to_a.flatten.compact.map(&:to_sym)

#       if taggable?
#         self.tag_types = (self.tag_types + tag_types).uniq
#         self.preserve_tag_order = preserve_tag_order
#       else
#         class_attribute :tag_types
#         self.tag_types = tag_types
#         class_attribute :preserve_tag_order
#         self.preserve_tag_order = preserve_tag_order
#         class_attribute :tenant_column

#         class_eval do
#           has_many :taggings, as: :taggable, dependent: :destroy, class_name: '::ActsAsTaggableOn::Tagging'
#           has_many :base_tags, through: :taggings, source: :tag, class_name: '::ActsAsTaggableOn::Tag'

#           def self.taggable?
#             true
#           end
#         end
#       end

#       # each of these add context-specific methods and must be
#       # called on each call of taggable_on
#       include Core
#       include Collection
#       include Cache
#       include Ownership
#       include Related
#     end

#   end
end
