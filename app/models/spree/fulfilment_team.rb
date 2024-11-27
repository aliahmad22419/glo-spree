class Spree::FulfilmentTeam < Spree::Base

  validates :name, uniqueness: true
  validates :code, uniqueness: true

  self.whitelisted_ransackable_associations = %w[zones]
  self.whitelisted_ransackable_attributes = %w[name code]

  has_and_belongs_to_many :zones, class_name: 'Spree::Zone'
  has_and_belongs_to_many :users, class_name: 'Spree::User'
  
end