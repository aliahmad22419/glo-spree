module Spree
  class HtmlLink < Spree::Base
    belongs_to :resource, polymorphic: true
    enum link_type: { generic: 0, mail: 1, tel: 2 }
  end
end
