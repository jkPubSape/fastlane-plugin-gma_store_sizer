module Fastlane
  module Actions

    module SharedValues
      REPORTING_CREDENTIALS_PLIST = :REPORTING_CREDENTIALS_PLIST
    end

    class GmaStoreSizePreflightAction < Action

      def self.run(params)
        require 'plist'
        require 'securerandom'

        #this is added as a test.  to make sure that if this fails due to version issues, it does so early.
        randomTest = SecureRandom.uuid


        # get version number
        versionCommand = "xcodebuild -showBuildSettings"
        versionCommand << " -project #{params[:project_path]}" if params[:project_path]
        versionCommand << " | grep MARKETING_VERSION | tr -d 'MARKETING_VERSION ='"
        buildVersion=FastlaneCore::CommandExecutor.execute(command: versionCommand, print_command: false, print_all: false)
        Actions.lane_context[SharedValues::VERSION_NUMBER] = buildVersion

        # get build number
        buildCommand = "xcodebuild -showBuildSettings"
        buildCommand << " -project #{params[:project_path]}" if params[:project_path]
        buildCommand << " | grep CURRENT_PROJECT_VERSION | tr -d 'CURRENT_PROJECT_VERSION ='"
        buildNumber=FastlaneCore::CommandExecutor.execute(command: buildCommand, print_command: false, print_all: false)
        Actions.lane_context[SharedValues::BUILD_NUMBER] = buildNumber

        # check for reporing plist
        filetest = true
        filetest = File.file?(params[:reporting_credentials_plist]) if params[:reporting_credentials_plist]

        # pull reporting creds plist
        reporting_options = {}
        reporting_options.merge!(Plist.parse_xml(params[:reporting_credentials_plist])) if params[:reporting_credentials_plist]

        #TODO: validate plist, check for key/value pairs.

        Actions.lane_context[SharedValues::REPORTING_CREDENTIALS_PLIST] = reporting_options

        UI.message("Version Number has been set to: #{Actions.lane_context[SharedValues::VERSION_NUMBER]}")
        UI.message("Build Number has been set to: #{Actions.lane_context[SharedValues::BUILD_NUMBER]}")

        UI.test_failure!("Error: could not find reporting plist file.") if !filetest
        UI.success("Preflight Check succeeded") 
      end

      def self.description
        "Preflight check is used to handle check that we have what we need before starting a long export"
      end

      def self.authors
        ["Johnathon Karcz"]
      end

      def self.output
      end

      def self.return_value
      end

      def self.details
        "User could pass in project path to retrieve version and build numbers.  Also could pass in reporting details to check if paths are good."
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
          FastlaneCore::ConfigItem.new(key: :project_path,
                                       description: 'Path to project file or project workspace',
                                       default_value: nil,
                                       optional: true,
                                       env_name: 'VERSION_PROJECT_PATH',
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
