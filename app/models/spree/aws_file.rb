module Spree
  class AwsFile < Spree::Base
    default_scope { where.not(active: false) }
    has_one_attached :attachment, service: :client_assets
    belongs_to :client, class_name: 'Spree::Client'
    self.whitelisted_ransackable_attributes = %w[name comment]
    validates :name, presence: true, on: :update

    before_create :save_cdn_url
    before_destroy -> { self.attachment.purge_later }

    def self.aws_file_created_at_scope(date)
      where(created_at: DateTime.parse(date).beginning_of_day..DateTime.parse(date).end_of_day)
    end

    def self.ransackable_scopes(auth_object = nil)
      [:aws_file_created_at_scope]
    end

    private
    
    def save_cdn_url
      self.url = "#{ENV['TS_CLIENT_ASSETS_CDN_HOST']}/#{attachment.key}" if self.attachment.attached?
    end
  end
end
