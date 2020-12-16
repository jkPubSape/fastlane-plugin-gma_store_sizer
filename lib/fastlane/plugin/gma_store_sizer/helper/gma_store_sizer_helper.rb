module Fastlane
  module Helper
    class GmaStoreSizerHelper
      def self.write_random_segments(file_path, segments)
        File.open(file_path, "rb+") do |file|
          segments.each do |segment|
            file.pos = segment[0]
            file.puts(SecureRandom.random_bytes(segment[1]))
          end
        end
      end

      def self.write_random_file(path, size)
        IO.binwrite(path, SecureRandom.random_bytes(size))
      end

      def self.xcode_export_package(archive_path, export_options_plist_path, export_path)
        require 'shellwords'
        # modified from just xcodebuild to fix issue i was getting when exporting ad-hoc build
        # error: exportArchive: The data couldn’t be read because it isn’t in the correct format.
        # oddly enough, this was an RVM issue
        command = "/usr/bin/xcrun #{self.script}"
        command << " -exportArchive"
        command << " -exportOptionsPlist #{Shellwords.escape(export_options_plist_path)}"
        command << " -archivePath #{Shellwords.escape(archive_path)}"
        command << " -exportPath #{Shellwords.escape(export_path)}"

        UI.message("JK TESTING - with shellwords")
        UI.message("export_options_plist_path: #{Shellwords.escape(export_options_plist_path)}")
        UI.message("archive_path: #{Shellwords.escape(archive_path)}")
        UI.message("export_path: #{Shellwords.escape(export_path)}")

        UI.message("Here is the command\n #{command}")

        FastlaneCore::CommandExecutor.execute(command: command, print_command: false, print_all: false)
      end

      def self.script
        File.expand_path('../scripts/xcbuild-safe.sh', File.dirname(__FILE__))
      end
    end
  end
end
