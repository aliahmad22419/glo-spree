module Spree
  class EmbedWidget < Spree::Base
    belongs_to :client, :class_name => 'Spree::Client'
  end
end
