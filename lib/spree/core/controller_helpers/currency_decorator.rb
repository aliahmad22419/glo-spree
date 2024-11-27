module Spree
  module Core
    module ControllerHelpers
      module CurrencyDecorator
        def current_currency
          @current_currency ||= if defined?(session) && session.key?(:currency) && supported_currency?(session[:currency])
                                  session[:currency]
                                elsif params[:currency].present? && supported_currency?(params[:currency])
                                  params[:currency]
                                elsif current_store.present?
                                  current_store.default_currency
                                else
                                  Spree::Config[:currency]
                                end&.upcase
        end
      end
    end
  end
end

Spree::Core::ControllerHelpers::Currency.prepend Spree::Core::ControllerHelpers::CurrencyDecorator
