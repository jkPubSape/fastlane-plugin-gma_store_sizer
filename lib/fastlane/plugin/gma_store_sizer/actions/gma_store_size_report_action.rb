module Fastlane
  module Actions
    
    # Reporting Credentials
    class NewRelicReportingCredentialKeys
      APP_NAME_KEY = "appName".freeze
      APP_ID_KEY = "appId".freeze
      INSIGHTS_INSERT_KEY = "insightsInsertKey".freeze
      ACCOUNT_NUMBER_KEY = "accountNumber".freeze
    end

    class GmaStoreSizeReportAction < Action

      $shouldConvertSizeValues = false

      MEGABYTE = 1048576.0.freeze
      # NewRelic Event Keys
      EVENT_TYPE = "eventType".freeze
      APP_VERSION = "appVersion".freeze
      APP_BUILD = "appBuild".freeze
      APP_NAME = "appName".freeze
      APP_ID = "appId".freeze
      VARIANT = "variant".freeze
      SUPPORTED_DEVICES = "supportedDevices".freeze
      DOWNLOAD_SIZE_WITH_RESOURCES = "downloadSizeAppWithResources".freeze
      INSTALL_SIZE_WITH_RESOURCES = "installSizeAppWithResources".freeze
      BUILD_SIZE = "buildSizeApp".freeze
      DOWNLOAD_SIZE = "downloadSizeApp".freeze
      INSTALL_SIZE = "installSizeApp".freeze
      DOWNLOAD_SIZE_RESOURCES = "downloadSizeAppResources".freeze
      INSTALL_SIZE_RESOURCES = "installSizeResources".freeze
      # NewRelic event Name
      EVENT_TYPE_VALUE = "AppSizeDataTest".freeze
      # NewRelic Request Headers
      HEADER_CONTENT_TYPE = "application/json".freeze
      HEADER_X_INSERT_KEY = "X-Insert-Key".freeze

      def self.run(params)
        require 'plist'

        @shouldConvertSizeValues = params[:report_sizes_in_mb]

        report = Actions.lane_context[SharedValues::SIZE_PLIST]
        reporting_options = {}
        reporting_options.merge!(Plist.parse_xml(params[:reporting_credentials_plist])) if params[:reporting_credentials_plist]

        Actions.lane_context[SharedValues::REPORTING_CREDENTIALS_PLIST] = reporting_options

        UI.test_failure!("Error: no variants in size plist") if report[Helper::AppThinningPlistKeys::VARIANTS].nil?
        
        jsonDataArray = []

        if !report[Helper::AppThinningPlistKeys::VARIANTS].nil?
          report[Helper::AppThinningPlistKeys::VARIANTS].each do |name, variant|
            next if variant[Helper::AppThinningPlistKeys::VARIANT_DESCRIPTORS].nil? && params[:ignore_universal]

            jsonData = Hash.new

            string = String.new
            deviceArray = []
            # create supported device list (current solution is one string with all device variants)
            if variant.key?(Helper::AppThinningPlistKeys::VARIANT_DESCRIPTORS) then 
              variant[Helper::AppThinningPlistKeys::VARIANT_DESCRIPTORS].each do |descriptor|
                # example of formatting: iPhone10,4; 13.0,
                deviceArray.push("#{descriptor[Helper::AppThinningPlistKeys::DEVICE]}; #{descriptor[Helper::AppThinningPlistKeys::OS_VERSION]}")
              end
            else
              deviceArray.push("Universal")
            end

            jsonData[EVENT_TYPE] = EVENT_TYPE_VALUE
            jsonData[APP_VERSION] = Actions.lane_context[SharedValues::VERSION_NUMBER]
            jsonData[APP_BUILD] = Actions.lane_context[SharedValues::BUILD_NUMBER]
            jsonData[APP_NAME] = reporting_options[NewRelicReportingCredentialKeys::APP_NAME_KEY]
            jsonData[APP_ID] = reporting_options[NewRelicReportingCredentialKeys::APP_ID_KEY]
            jsonData[VARIANT] = name.gsub(Helper::AppThinningPlistKeys::VARIANT_NAME_SUBSTRING, '')
            jsonData[SUPPORTED_DEVICES] = deviceArray.join(', ')
            jsonData[DOWNLOAD_SIZE_WITH_RESOURCES] = convert_size_value(variant[Helper::AppThinningPlistKeys::SIZE_COMPRESSED_APP_ODR])
            jsonData[INSTALL_SIZE_WITH_RESOURCES] = convert_size_value(variant[Helper::AppThinningPlistKeys::SIZE_COMRESSED_APP_ODR])
            jsonData[BUILD_SIZE] = convert_size_value(variant[Helper::AppThinningPlistKeys::SIZE_COMRESSED_APP]) # note: this value is the same as download on ios, for android it will be differnt. 
            jsonData[DOWNLOAD_SIZE] = convert_size_value(variant[Helper::AppThinningPlistKeys::SIZE_COMRESSED_APP])
            jsonData[INSTALL_SIZE] = convert_size_value(variant[Helper::AppThinningPlistKeys::SIZE_UNCOMRESSED_APP])
            jsonData[DOWNLOAD_SIZE_RESOURCES] = convert_size_value(variant[Helper::AppThinningPlistKeys::SIZE_COMRESSED_ODR])
            jsonData[INSTALL_SIZE_RESOURCES] = convert_size_value(variant[Helper::AppThinningPlistKeys::SIZE_UNCOMRESSED_ODR])
            # note there is also and option for a boolean sizeUncompressedInitialPrefetchedODRExceedsLimit and limitUncompressedInitialPrefetchedODR

            jsonDataArray << jsonData
          end
        end
        
        post_to_new_relic(jsonDataArray)
      end

      private 
      def self.convert_size_value(size) 
        if @shouldConvertSizeValues then
          (size/MEGABYTE).round(1)
        else
          return size
        end
      end

      def self.print_new_relic_request_data(eventArray)
        require 'json'
        puts "PRINT DATA WE ARE ABOUT TO SEND - EVENT DATA"
        puts JSON[eventArray]
      end

      def self.test_print_new_relic_credentials()
        puts "PRINTING NEWRELIC DATA"
        accountData = Actions.lane_context[SharedValues::REPORTING_CREDENTIALS_PLIST]
        puts accountData[NewRelicReportingCredentialKeys::ACCOUNT_NUMBER_KEY]
        puts accountData[NewRelicReportingCredentialKeys::INSIGHTS_INSERT_KEY]
        puts accountData[NewRelicReportingCredentialKeys::APP_ID_KEY]
        puts accountData[NewRelicReportingCredentialKeys::APP_NAME_KEY]
      end

      def self.post_to_new_relic(eventArray)
        require 'json'
        require 'net/http'
        require 'uri'

        accountData = Actions.lane_context[SharedValues::REPORTING_CREDENTIALS_PLIST]

        uri = URI.parse("https://insights-collector.newrelic.com/v1/accounts/#{accountData[NewRelicReportingCredentialKeys::ACCOUNT_NUMBER_KEY]}/events")
        request = Net::HTTP::Post.new(uri)
        request.content_type = HEADER_CONTENT_TYPE
        request[HEADER_X_INSERT_KEY] = accountData[NewRelicReportingCredentialKeys::INSIGHTS_INSERT_KEY]
        request.body = JSON[eventArray]

        req_options = {
          use_ssl: uri.scheme == "https",
        }

        response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
          http.request(request)
        end

        # puts response.code
        # puts response.body

        # note that NewRelic could respond with 200 even in case of data errors; check this with the following query
        # SELECT message FROM NrIntegrationError WHERE newRelicFeature = 'Event API' AND category = 'EventApiException'
        UI.test_failure!("Reporting to newRelic failed, error: #{response.body}") if response.code != "200"

        UI.success("App size reporting succeeded")

      end 

      def self.description
        "Reports appsizes to newRelic"
      end

      def self.authors
        ["Johnathon Karcz"]
      end

      def self.output
      end

      def self.return_value
      end

      def self.details
        "Gets app sizes and reports them to newRelic"
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :reporting_credentials_plist,
                                       description: 'Path to plist with the newrelic account data',
                                       default_value: nil,
                                       optional: true,
                                       env_name: 'STORE_SIZE_REPORTING_CREDENTIALS_PLIST',
                                       verify_block: proc do |value|
                                         UI.user_error!("Couldn't find reporting plist file at path '#{value}'") if !Helper.test? && !File.exist?(value)
                                       end),
          FastlaneCore::ConfigItem.new(key: :ignore_universal,
                             description: 'True to ignore universal variant',
                             default_value: false,
                             is_string: false,
                             optional: true),
          FastlaneCore::ConfigItem.new(key: :report_sizes_in_mb,
                             description: 'Set to false if you would like values in newrelic to be in bytes instead of megabytes',
                             default_value: true,
                             is_string: false,
                             optional: true)
        ]
      end

      def self.is_supported?(platform)
        [:ios].include?(platform)
      end
    end
  end
end
