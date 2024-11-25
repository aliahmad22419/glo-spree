module Spree::XssValidationConcern

  REGEX_OPTIONS = Regexp::IGNORECASE | Regexp::EXTENDED

  FORBIDDEN_TAGS = /<script|\bjavascript\s*:|\bexpression\s*\(|\bonabort\s*=|\bonafterprint\s*=|\bonanimationend\s*=|\bonanimationiteration\s*=|\bonanimationstart\s*=|
                      \bonbeforeprint\s*=|\bonbeforeunload\s*=|\bonblur\s*=|\boncanplay\s*=|\boncanplaythrough\s*=|\bonchange\s*=|\bonclick\s*=|\boncontextmenu\s*=|\boncopy\s*=|
                      \boncut\s*=|\bondblclick\s*=|\bondrag\s*=|\bondragend\s*=|\bondragenter\s*=|\bondragleave\s*=|\bonhashchange\s*=|\boninput\s*=|\boninvalid\s*=|\bonkeydown\s*=|
                      \bonkeypress\s*=|\bonkeyup\s*=|\bonload\s*=|\bonloadeddata\s*=|\bonloadedmetadata\s*=|\bonloadstart\s*=|\bonmessage\s*=|\bonmousedown\s*=|\bondragover\s*=|
                      \bondragstart\s*=|\bondrop\s*=|\bondurationchange\s*=|\bonended\s*=|\bonerror\s*=|\bonfocus\s*=|\bonfocusin\s*=|\bonfocusout\s*=|\bonfullscreenchange\s*=|
                      \bonfullscreenerror\s*=|\bonselect\s*=|\bonshow\s*=|\bonstalled\s*=|\bonstorage\s*=|\bonsubmit\s*=|\bonsuspend\s*=|\bontimeupdate\s*=|\bontoggle\s*=|
                      \bontouchcancel\s*=|\bontouchend\s*=|\bontouchmove\s*=|\bontouchstart\s*=|\bonmouseenter\s*=|\bonmouseleave\s*=|\bonmousemove\s*=|\bonmouseover\s*=|
                      \bonmouseout\s*=|\bonmouseup\s*=|\bonmousewheel\s*=|\bonoffline\s*=|\bononline\s*=|\bonopen\s*=|\bonpagehide\s*=|\bdata\s*:|onpaste\s*=|\bonpause\s*=|
                      \bonplay\s*=|\bonplaying\s*=|\bonpopstate\s*=|\bonprogress\s*=|\bonratechange\s*=|\bonresize\s*=|\bonreset\s*=|\bonscroll\s*=|\bonsearch\s*=|
                      \bonseeked\s*=|\bonseeking\s*=|\bontransitionend\s*=|\bonunload\s*=|\bonvolumechange\s*=|\bonwaiting\s*=|\bonwheel\s*=|
                      \bonpageshow=|&lt;script|&lt;data|&lt;embed|&lt;base|&lt;object|&lt;iframe|<iframe|<data|<embed|<base|<object|\bdata\s*=/xi

  SQL_PATTERNS = /\bSELECT\s+(?:(?!=>).)*\s+FROM\s+\w+(\s+WHERE\s+.*)?(\s+GROUP\s+BY\s+.*)?(\s+ORDER\s+BY\s+.*)?(\s+JOIN\s+\w+ON\s+.*)?\s*|
                    \bINSERT\s+(IGNORE\s+)?INTO\s+\w+\s*\((?![^()]*=>[^()]*\)).*\)\s+VALUES\s*\(.*\)(,\s*\(.*\))*\s*|
                    \bUPDATE\s+\w+\s+SET\s+[\w\s,=']+(?:WHERE\s+[\w\s='><,!]+)?\s*;?\s*|
                    \bDROP\s+(TABLE|INDEX|VIEW)\s+\w+\s*;?\s*|
                    \bALTER\b\s+\bTABLE\b\s+\w+\s+(ADD|DROP|MODIFY|ALTER|RENAME)\s+\w+|
                    \bTRUNCATE\b\s+\bTABLE\b\s+\w+|
                    \bMERGE\s+INTO\s+\w+\s+USING\s+\w+\s+ON\s+\([^)]+\)\s+WHEN\s+MATCHED\s+THEN\s+|
                    \bMERGE\s+INTO\s+\w+\s+USING\s+\w+\s+ON\b|
                    \bCREATE\s+(TABLE|INDEX|VIEW|ROLE)\s+\w+\s*|
                    \bDELETE\s+FROM\s+\w+\s*(?:WHERE\s+[\w\s=><,!]+)?\s*;?\s*/xi

  FORBIDDEN_JS_SQL = Regexp.new(FORBIDDEN_TAGS.source + '|' + SQL_PATTERNS.source, REGEX_OPTIONS)

  # Update whitelist regex according to FORBIDDEN_TAGS.source string
  # Example: whitelist the following
  # /\\bondblclick\\s\*=\||\\bjavascript\\s\*:\||\\bexpression\\s\*\\\(\|/
  # from FORBIDDEN_TAGS.source string

  WHITELISTED_TAGS = {
    html_components: {
      actions: {
        update: /&lt;iframe\||<iframe\|/
      }
    }
  }

  def self.included(base)
    base.class_eval do
      before_action :update_forbidden_tags
      before_action :validate_xss_params, if: Proc.new { request.post? || request.put? || request.patch? }

      def validate_xss_params
        return render json: { error: 'Unprocessable Entity' }, status: :unprocessable_entity if params.to_s.match? @forbidden_tags
      end

      def forbidden_tag_exist?(value)
        return unless value.is_a?(String)
        value.match? @forbidden_tags
      end

      def sanitize_xss_tags(value)
        value.is_a?(String) ? value.gsub(@forbidden_tags, '') : value
      end

      def update_forbidden_tags
        @forbidden_tags = FORBIDDEN_JS_SQL
        white_listed_tags = WHITELISTED_TAGS[controller_name.to_sym]&.[](:actions)&.[](action_name.to_sym)
        @forbidden_tags = Regexp.new(@forbidden_tags.source.gsub!(white_listed_tags, ''), REGEX_OPTIONS) if white_listed_tags
      end
    end

    def self.forbidden_tag_exist?(value)
      return unless value.is_a?(String)
      value.match? FORBIDDEN_JS_SQL
    end
  end
end
