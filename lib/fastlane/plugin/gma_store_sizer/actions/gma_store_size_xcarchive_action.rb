module Fastlane
  module Actions
    module SharedValues
      SIZE_REPORT = :SIZE_REPORT
      SIZE_PLIST = :SIZE_PLIST
    end

    class GmaStoreSizeXcarchiveAction < Action
      EXTRA_FILE_SIZE = 2_000_000

      EXPORT_OPTIONS_PLIST_METHOD_KEY = "method".freeze
      EXPORT_OPTIONS_PLIST_PROVISIONING_KEY = "provisioningProfiles".freeze
      EXPORT_OPTIONS_PLIST_THINNING_KEY = "thinning".freeze

      EXPORT_OPTIONS_PLIST_METHOD_VALUE = 'ad-hoc'.freeze
      EXPORT_OPTIONS_PLIST_THINNING_VALUE = '<thin-for-all-variants>'.freeze

      EXPORT_OPTIONS_PLIST_FILE_NAME = "ExportOptions.plist".freeze
      APP_THINNING_PLIST_FILE_NAME = "app-thinning.plist".freeze
      APP_THINNING_REPORT_FILE_NAME = "App Thinning Size Report.txt".freeze

      def self.run(params)
        require 'plist'
        unless Fastlane::Helper.test?
          UI.user_error!("xcodebuild not installed") if `which xcodebuild`.length == 0
        end

        archive_path = params[:archive_path] || Actions.lane_context[SharedValues::XCODEBUILD_ARCHIVE]
        app_path = Dir.glob(File.join(archive_path, "Products", "Applications", "*.app")).first
        UI.user_error!("No applications found in archive") if app_path.nil?

        binary_name = File.basename(app_path, ".app")
        binary_path = File.join(app_path, binary_name)
        extra_file_path = File.join(app_path, "extradata_simulated")
        result = {}

        Dir.mktmpdir do |tmp_path|
          binary_backup_path = File.join(tmp_path, binary_name)
          export_path = File.join(tmp_path, "Export")
          begin
            FileUtils.mv(binary_path, binary_backup_path)
            FileUtils.cp(binary_backup_path, binary_path)

            macho_info = Helper::MachoInfo.new(binary_path)

            Helper::GmaStoreSizerHelper.write_random_segments(binary_path, macho_info.encryption_segments)
            Helper::GmaStoreSizerHelper.write_random_file(extra_file_path, EXTRA_FILE_SIZE)

            export_options = {}
            export_options.merge!(Plist.parse_xml(params[:export_plist])) if params[:export_plist]
            export_options[EXPORT_OPTIONS_PLIST_METHOD_KEY] = EXPORT_OPTIONS_PLIST_METHOD_VALUE
            # export_options[EXPORT_OPTIONS_PLIST_PROVISIONING_KEY] = {ENV["MATCH_APP_IDENTIFIER"] => ENV["sigh_#{ENV["MATCH_APP_IDENTIFIER"]}_adhoc_profile-name"]}
            export_options[EXPORT_OPTIONS_PLIST_THINNING_KEY] = params[:thinning] || EXPORT_OPTIONS_PLIST_THINNING_VALUE
            export_options_plist_path = File.join(tmp_path, EXPORT_OPTIONS_PLIST_FILE_NAME)
            
            UI.message("here is the plist file used for export")
            UI.message(export_options)

            File.write(export_options_plist_path, Plist::Emit.dump(export_options, false))

            UI.message("Exporting all variants of #{archive_path} for estimation...")
            Helper::GmaStoreSizerHelper.xcode_export_package(archive_path, export_options_plist_path, export_path)

            UI.verbose(File.read(File.join(export_path, APP_THINNING_REPORT_FILE_NAME)))

            result = Plist.parse_xml(File.join(export_path, APP_THINNING_PLIST_FILE_NAME))
            Actions.lane_context[SharedValues::SIZE_PLIST] = result
            result.merge!(macho_info.sizes_info)

          ensure
            FileUtils.rm_f(binary_path)
            FileUtils.mv(binary_backup_path, binary_path)
            FileUtils.rm_f(extra_file_path)
          end
        end

        Actions.lane_context[SharedValues::SIZE_REPORT] = result
        result
      end

      def self.description
        "Estimates download and install sizes for your app"
      end

      def self.authors
        ["Marcelo Oliveira"]
      end

      def self.output
        [
          ['SIZE_REPORT', 'The generated size report hash']
        ]
      end

      def self.return_value
        "Hash containing App Thinning report"
      end

      def self.details
        "Compute estimated size of the .ipa after encryption and App Thinning for all variants"
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :archive_path,
                                       description: 'Path to your xcarchive file. Optional if you use the `xcodebuild` action',
                                       default_value: Actions.lane_context[SharedValues::XCODEBUILD_ARCHIVE],
                                       optional: true,
                                       env_name: 'STORE_SIZE_ARCHIVE_PATH',
                                       verify_block: proc do |value|
                                         UI.user_error!("Couldn't find xcarchive file at path '#{value}'") if !Helper.test? && !File.exist?(value)
                                       end),
          FastlaneCore::ConfigItem.new(key: :export_plist,
                                       description: 'Path to your existing export options plist with the codesigning stuff',
                                       default_value: nil,
                                       optional: true,
                                       env_name: 'STORE_SIZE_EXPORT_OPTIONS_PLIST',
                                       verify_block: proc do |value|
                                         UI.user_error!("Couldn't find plist file at path '#{value}'") if !Helper.test? && !File.exist?(value)
                                       end),
          FastlaneCore::ConfigItem.new(key: :thinning,
                                       description: 'How should Xcode thin the package? e.g. <none>, <thin-for-all-variants>, or a model identifier for a specific device (e.g. "iPhone7,1")',
                                       default_value: '<thin-for-all-variants>',
                                       optional: true,
                                       env_name: 'STORE_SIZE_THINNING')
        ]
      end

      def self.is_supported?(platform)
        [:ios].include?(platform)
      end
    end
  end
end
