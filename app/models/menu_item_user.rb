class MenuItemUser < ApplicationRecord
    has_many :sub_menu_item_users, class_name: "MenuItemUser", foreign_key: "parent_id", dependent: :destroy
    belongs_to :user, class_name: "Spree::User"
    belongs_to :menu_item, class_name: "MenuItem"

    validates :menu_item_id, uniqueness: { scope: :user_id }

    after_create :create_sub_menus
    after_destroy :destroy_sub_menus
    before_create :set_parent_for_permissive_items, if: -> { self.menu_item.parent.present? }
    scope :visible, -> { where(visible: true) }
    scope :invisible, -> { where(visible: false) }
    scope :permissible, -> { where(permissible: true) }
    scope :parent_menus, -> { where(parent_id: nil) }

    private

    def set_parent_for_permissive_items
      self.parent_id =  self.user.menu_item_users.find_by(menu_item_id: self.menu_item.parent_id).id
    end

    def create_sub_menus
      # While creating parent menu item user, assign child permissions automatically
      # those are neither visible nor permissible
      self.menu_item.sub_menu_items.invisible.nonpermissible.each do |item|
        item.menu_item_users.create(user_id: self.user_id, parent_id: self.id, visible: item.visible, permissible: item.permissible)
      end
    end

    def destroy_sub_menus
      MenuItemUser.where(parent_id: self.id).destroy_all
    end
end