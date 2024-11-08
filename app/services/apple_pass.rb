class ApplePass
  attr_accessor :card, :json, :pk_pass, :passbook, :store, :assets, :images, :currency_symbol

  def initialize(ts_giftcard)
    @card = ts_giftcard
    @store = @card.line_item.store
    @images = @card.line_item.variant.images
    @images = @card.line_item.product.images unless @images.present?
    @passbook = @store.apple_passbook
    @currency_symbol = Spree::Money.new(currency: @card.line_item.currency).currency.symbol
    @assets = OpenStruct.new()
  end

  # Folder structure is required as all files are downloaded locally
  # and deleted after being attached to ts card pass file
  def create_folder
    @assets.walletpath = "#{Rails.root.to_s}/tmp/apple_passes"
    FileUtils.mkdir_p(@assets.walletpath) unless Dir.exist?(@assets.walletpath)

    @assets.storepath = "#{@assets.walletpath}/#{@store.name.parameterize(separator: '_')}_#{@store.id}"
    FileUtils.mkdir(@assets.storepath) unless Dir.exist?(@assets.storepath)

    @assets.cardpath = "#{@assets.storepath}/card_#{@card.id}"
    FileUtils.mkdir(@assets.cardpath) unless Dir.exist?(@assets.cardpath)

    @assets.certspath = "#{@assets.cardpath}/certs"
    FileUtils.mkdir(@assets.certspath) unless Dir.exist?(@assets.certspath)

    @assets.imagespath = "#{@assets.cardpath}/images"
    FileUtils.mkdir(@assets.imagespath) unless Dir.exist?(@assets.imagespath)
  end

  private

  def attach
    return unless @passbook.present? && @passbook.preferred_enable

    begin
      attach_pk_pass
    rescue => e
      @card.log_entries.create!(details: e.message.to_s)
    end
  end

  def attach_pk_pass
    create_folder
    certify
    build
    attach_images

    # attach file to passbook
    @pass_file_name = @card.line_item.product.name&.split()&.collect(&:capitalize)&.join&.first(30)
    @pass_file_name ||= @store.name.split().collect(&:capitalize).join

    pkpass_file_path = "#{@assets.cardpath}/#{@pass_file_name}.pkpass"

    pkpass_file = File.open(pkpass_file_path, 'w')
    pkpass_file.write @pk_pass.stream.string.force_encoding('UTF-8')
    pkpass_file.close

    remove_folder if @card.pk_pass.attach(io: File.open(pkpass_file_path), filename: "#{@pass_file_name}.pkpass")
  end

  def certify
    # Download certificate locally
    file_path = "#{@assets.certspath}/#{@store.passbook_certificate.filename}"

    file = File.open(file_path, 'wb')
    file.write(@store.passbook_certificate.download)
    file.close

    # Add certificates
    Passbook.p12_certificate = file_path
    Passbook.wwdc_cert = Rails.root.join('passbook', 'certs', 'wwdr.cer').to_s
    Passbook.p12_password = @passbook.p12_password
  end

  def build
    ts_pass_json

    signer = Passbook::Signer.new(@json)
    @pk_pass = Passbook::PKPass.new @json.to_json, signer
  end

  def ts_pass_json
    @json = JSON.parse(@passbook.pass)
    json_style = @json['coupon'] || @json['boardingPass'] || @json['eventTicket'] || @json['storeCard'] || @json['generic']

    build_barcode
    @json['serialNumber'] = @card.id.to_s unless @json['serialNumber'].present?

    json_style.keys.select{ |key| json_style[key].is_a?(Array) }.each do |upper_key|
      # Find and update balance in pass json
      json_style[upper_key].select{ |obj| obj['key'].include?('balance') }.each do |balance|
        balance['value'] = (@card.line_item.currency + @currency_symbol + ('%.2f' % @card.balance.to_f))
      end

      # Find and update card number in pass json
      json_style[upper_key].select{ |obj| obj['key'].include?('card-number') }.each do |card|
        card['value'] = (@card.class.eql?(Spree::GivexCard) ? @card.givex_number : @card.number)
      end

      # Find and remove or update expiry date in pass json
      json_style[upper_key].select{ |obj| obj['key'].include?('expiry-date') }.each do |expiry|
        if @card.respond_to?(:expiry_date) && @card.expiry_date.present?
          expiry['value'] = @card.expiry_date.strftime("%m/%d/%Y")
        else
          json_style[upper_key].delete(expiry)
        end
      end
    end
  end

  def build_barcode
    barcodes = @json['barcodes'][0] if @json['barcodes'].present?

    if barcodes.present?
      barcodes['message'] = (@card.class.eql?(Spree::GivexCard) ? @card.givex_number : @card.number)
      # barcodes['format'] = (@passbook.barcode_format.eql?('qrcode') ? 'PKBarcodeFormatQR' : 'PKBarcodeFormatCode128')
    end
  end

  def attach_images
    icon_url = @json['iconUrl'] || product_image_url
    @card.log_entries.create!(details: 'Missing icon') and return unless icon_url.present?

    @pk_pass.addFile download_attachment_blob(icon_url, "#{@assets.imagespath}/icon.png")
    @pk_pass.addFile download_attachment_blob(icon_url, "#{@assets.imagespath}/icon@2x.png")
    @pk_pass.addFile download_attachment_blob(@json['logoUrl'], "#{@assets.imagespath}/logo.png") if @json['logoUrl'].present?
    @pk_pass.addFile download_attachment_blob(@json['logoUrl'], "#{@assets.imagespath}/logo@2x.png") if @json['logoUrl'].present?
    @pk_pass.addFile download_attachment_blob(@json['thumbnailUrl'], "#{@assets.imagespath}/thumbnail.png") if @json['thumbnailUrl'].present?
    @pk_pass.addFile download_attachment_blob(@json['thumbnailUrl'], "#{@assets.imagespath}/thumbnail@2x.png") if @json['thumbnailUrl'].present?
    @pk_pass.addFile download_attachment_blob(@json['stripUrl'], "#{@assets.imagespath}/strip.png") if @json['stripUrl'].present?
    @pk_pass.addFile download_attachment_blob(@json['stripUrl'], "#{@assets.imagespath}/strip@2x.png") if @json['stripUrl'].present?
  end

  def product_image_url
    img = @images[0]
    @store.active_storge_url(img.attachment) if img.present?
  end

  def download_attachment_blob url, path
    file = File.open(path, 'wb')
    file.write(open(url) {|f| f.read })
    file.close

    path
  end

  def remove_folder
    FileUtils.rm_rf(Dir[@assets.cardpath])
  end
end
