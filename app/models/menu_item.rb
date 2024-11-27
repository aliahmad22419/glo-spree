class MenuItem < ApplicationRecord
    has_many :menu_item_users, dependent: :destroy
    has_many :users, through: :menu_item_users
    has_many :sub_menu_items, class_name: "MenuItem", foreign_key: "parent_id", dependent: :destroy
    belongs_to :parent, class_name: "MenuItem", foreign_key: "parent_id", optional: true

    validates :url, uniqueness: { scope: :name }

    scope :visible, -> { where(visible: true) }
    scope :invisible, -> { where(visible: false) }
    scope :permissible, -> { where(permissible: true) }
    scope :nonpermissible, -> { where(permissible: false) }
    scope :parent_menus, -> { where(parent_id: nil) }
    scope :items_with_role, -> (roles){ where('menu_permission_roles @> ARRAY[?]::text[]', roles) }
    after_create :update_admin_persona

    def menu_item_hash(user)
      {id: id, name: name, url: user.menu_item_url(self), imgUrl: img_url, priority: priority, visible: visible, permissible: permissible}
    end

    def update_admin_persona
      return if ['/sub-client-landing', '/stock-product/:id'].include?(self.url)
      return unless self.menu_permission_roles.include?('sub_client')

      admin_personas = Spree::Persona.where(persona_code: 'admin')
      admin_personas.each do |persona|
        unless persona.menu_item_ids.include?(self.id.to_s)
          persona.menu_item_ids << self.id.to_s
          persona.save
        end
      end

      admin_users = Spree::User.joins(:spree_roles).where(spree_roles: { name: 'sub_client' }).where(persona_type: 'admin')
      admin_users.each do |admin_user|
        unless admin_user.menu_items.include?(self)
          if (self.parent.blank? || (self.parent.present? && admin_user.menu_items.include?(self.parent)))
            admin_user.menu_items << self
            admin_user.save(validate: false)
          end
        end
      end
    end
end
