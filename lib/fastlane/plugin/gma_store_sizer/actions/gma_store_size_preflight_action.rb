module Fastlane
  module Actions

    module SharedValues
      REPORTING_CREDENTIALS_PLIST = :REPORTING_CREDENTIALS_PLIST
    end

    class GmaStoreSizePreflightAction < Action

      def self.run(params)
        require 'plist'
        buildPlistPath=params[:info_plist_path]
        # get version number


        # Get the existing buildVersion and buildNumber values from the buildPlist
        versionCommand = "/usr/libexec/PlistBuddy"
        versionCommand << " -c \"Print CFBuildVersion\""
        versionCommand << " #{buildPlistPath}"

        buildVersion=FastlaneCore::CommandExecutor.execute(command: versionCommand, print_command: false, print_all: false)

        Actions.lane_context[SharedValues::VERSION_NUMBER] = buildVersion

        # get build number
        buildCommand = "/usr/libexec/PlistBuddy"
        buildCommand << " -c \"Print CFBundleVersion\""
        buildCommand << " #{buildPlistPath}"

        buildNumber=FastlaneCore::CommandExecutor.execute(command: buildCommand, print_command: false, print_all: false)

        Actions.lane_context[SharedValues::BUILD_NUMBER] = buildNumber
        # check for reporing plist
        filetest = true
        filetest = File.file?(params[:reporting_credentials_plist]) if params[:reporting_credentials_plist]


        # pull reporting creds plist
        reporting_options = {}
        reporting_options.merge!(Plist.parse_xml(params[:reporting_credentials_plist])) if params[:reporting_credentials_plist]

        Actions.lane_context[SharedValues::REPORTING_CREDENTIALS_PLIST] = reporting_options

        UI.test_failure!("Error: could not find reporting plist file.") if !filetest
        UI.success("Preflight Check succeeded")
        
      end

      private 
      # def self.convert_size_value(size) 
      #   if @shouldConvertSizeValues then
      #     (size/MEGABYTE).round(1)
      #   else
      #     return size
      #   end
      # end

      # def self.print_new_relic_request_data(eventArray)
      #   require 'json'
      #   puts "PRINT DATA WE ARE ABOUT TO SEND - EVENT DATA"
      #   puts JSON[eventArray]
      # end

      # def self.test_print_new_relic_credentials()
      #   puts "PRINTING NEWRELIC DATA"
      #   accountData = Actions.lane_context[SharedValues::REPORTING_CREDENTIALS_PLIST]
      #   puts accountData[NewRelicReportingCredentialKeys::ACCOUNT_NUMBER_KEY]
      #   puts accountData[NewRelicReportingCredentialKeys::INSIGHTS_INSERT_KEY]
      #   puts accountData[NewRelicReportingCredentialKeys::APP_ID_KEY]
      #   puts accountData[NewRelicReportingCredentialKeys::APP_NAME_KEY]
      # end

      # def self.post_to_new_relic(eventArray)
      #   require 'json'
      #   require 'net/http'
      #   require 'uri'

      #   accountData = Actions.lane_context[SharedValues::REPORTING_CREDENTIALS_PLIST]

      #   uri = URI.parse("https://insights-collector.newrelic.com/v1/accounts/#{accountData[NewRelicReportingCredentialKeys::ACCOUNT_NUMBER_KEY]}/events")
      #   request = Net::HTTP::Post.new(uri)
      #   request.content_type = HEADER_CONTENT_TYPE
      #   request[HEADER_X_INSERT_KEY] = accountData[NewRelicReportingCredentialKeys::INSIGHTS_INSERT_KEY]
      #   request.body = JSON[eventArray]

      #   req_options = {
      #     use_ssl: uri.scheme == "https",
      #   }

      #   response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
      #     http.request(request)
      #   end

      #   # puts response.code
      #   # puts response.body

      #   # note that NewRelic could respond with 200 even in case of data errors; check this with the following query
      #   # SELECT message FROM NrIntegrationError WHERE newRelicFeature = 'Event API' AND category = 'EventApiException'
      #   UI.test_failure!("Reporting to newRelic failed, error: #{response.body}") if response.code != "200"

      #   UI.success("App size reporting succeeded")

      # end 

      def self.description
        ""
      end

      def self.authors
        ["Johnathon Karcz"]
      end

      def self.output
      end

      def self.return_value
      end

      def self.details
        ""
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
          FastlaneCore::ConfigItem.new(key: :info_plist_path,
                                       description: 'Path to plist with version data',
                                       default_value: nil,
                                       optional: true,
                                       env_name: 'INFO_PLIST',
                                       verify_block: proc do |value|
                                         UI.user_error!("Couldn't find reporting plist file at path '#{value}'") if !Helper.test? && !File.exist?(value)
                                       end)
        ]
      end

      def self.is_supported?(platform)
        [:ios].include?(platform)
      end
    end
  end
end
