module ActiveMerchant #:nodoc:
  module Billing #:nodoc:
    # = Barclays ExtraPlus / DirectLink Gateway
    #
    # Barclays ePDQ is being phased out in favour of a product based on the Ogone
    # DirectLink Gateway, which is being marketed as "Barclays Extra Plus". It 
    # is the API version of the platform, as opposed to the e-commerce hosted 
    # pages of Barclays Extra Plus.
    #
    # This class is based upon the OgoneGateway class as it re-uses the same 
    # architecture, with different endpoints. Please refer to the OgoneGateway 
    # class for more information.
    #
    # == Setup Notes
    #
    # In order to enable API access with BarclaysExtraPlus, an API user 
    # must be created in the Barclays e-commerce backend. This user must have 
    # admin rights, and the checkbox "Special user for API (no access to admin.)"
    #
    # In order to use the ALIAS feature to store authorisations without 
    # storing card details, this feature must be enabled via a support ticket 
    # with Barclays. Then, the ALIAS variable must be added to the list of dynamic
    # parameters on the Technical Information > Transaction Feedback tab, and
    # a SHAOUT signature must be provided. 
    #
    # All the unit and remote tests passed with a BarclaysExtraPlus test account
    # on November 22nd, 2012.     
    #
    class BarclaysExtraPlusGateway < OgoneGateway
      
      BASE_URLS = {
        :test => 'https://mdepayments.epdq.co.uk/ncol/test',
        :production => 'https://payments.epdq.co.uk/ncol/prod'
      }
      
      URLS[:order] = '/orderdirect.asp'
      URLS[:maintenance] = '/maintenancedirect.asp'      
      
      self.test_url = BASE_URLS[:test] + URLS[:order]
      self.live_url = BASE_URLS[:production] + URLS[:order]

      # The countries the gateway supports merchants from as 2 digit ISO country codes
      self.supported_countries = ['GB']

      # The card types supported by the payment gateway
      self.supported_cardtypes = [:visa, :master, :american_express, :jcb, :maestro]

      # The homepage URL of the gateway
      self.homepage_url = 'http://www.barclaycard.co.uk/business/accepting-payments/epdq-ecomm/extraplus/'

      # The name of the gateway
      self.display_name = 'Barclays ePDQ Extra Plus'
      
      self.default_currency = 'GBP'

      def commit(action, parameters)
        add_pair parameters, 'PSPID',  @options[:login]
        add_pair parameters, 'USERID', @options[:user]
        add_pair parameters, 'PSWD',   @options[:password]

        url = BASE_URLS[test? ? :test : :production] + URLS[parameters['PAYID'] ? :maintenance : :order]
        response = parse(ssl_post(url, post_data(action, parameters)))

        options = {
          :authorization => [response["PAYID"], action].join(";"),
          :test          => test?,
          :avs_result    => { :code => AVS_MAPPING[response["AAVCheck"]] },
          :cvv_result    => CVV_MAPPING[response["CVCCheck"]]
        }
        OgoneResponse.new(successful?(response), message_from(response), response, options)
      end
      
      def store(payment_source, options = {})
        options.merge!(:alias_operation => 'BYPSP') unless options.has_key?(:billing_id) || options.has_key?(:store)
        response = authorize(1, payment_source, options)
        void(response.authorization) if response.success?
        response
      end
    end
  end
end

