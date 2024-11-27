
module Spree
  class Printables
    module BaseViewDecorator
      def self.prepended(base)
        base.attr_accessor :store_locale
      end

      SYSTEM_ALLOWED_LOCALES = %i[ar zh-Hans zh-Hant en fr de it ja cnr pt es th]

      def render_html(pdf, html)
        doc = Nokogiri::HTML(html)
        doc.xpath('//@style').each do |style_attr|
          updated_style = style_attr.value.gsub(/font-family:[^;]*;/, '').strip
          style_attr.value = updated_style
        end

        root_div = Nokogiri::XML::Node.new('div', doc)
        # add Arial family to root div
        root_div['style'] = "font-family: ArialEng;"
        root_div.inner_html = doc.to_html
        html = root_div.to_html
        PrawnHtml.append_html(pdf, html) rescue Nokogiri::HTML(html).text.strip
      end

      def variant_details
        data = Hash.new(0)
        printable.line_item.option_values_text.each do |hash|
          key, value = hash["value"].split(" : ")
          data[key] = value
        end
        data
      end

      def custom_options
        data = {}
        customizations = printable.line_item.line_item_customizations.order("spree_line_item_customizations.updated_at ASC")

        customizations.each do |customization|
          if data.key?(customization.name)
            data[customization.name] << ", #{customization.text}"
          else
            data[customization.name] = customization.text
          end
        end
        data
      end

      def set_locale
        return unless printable.is_a?(Spree::TsGiftcard) || printable.is_a?(Spree::GivexCard)

        @store_locale ||= printable.store.preferred_default_language.to_sym.presence_in(SYSTEM_ALLOWED_LOCALES) || :en
      end

      private

      def increase_invoice_number!
        Spree::PrintInvoice::Config.increase_invoice_number!
      end

      def use_sequential_number?
        @_use_sequential_number ||=
          Spree::PrintInvoice::Config.use_sequential_number?
      end
    end
  end
end

::Spree::Printables::BaseView.prepend Spree::Printables::BaseViewDecorator
