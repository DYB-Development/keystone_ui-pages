# frozen_string_literal: true

require "open3"
require "tmpdir"
require "keystone_ui/pages"

module KeystoneUi
  module Pages
    class PrintFailed < StandardError; end

    module Printer
      module_function

      def pdf(html)
        Dir.mktmpdir do |folder|
          page = File.join(folder, "page.html")
          printed = File.join(folder, "page.pdf")
          File.write(page, html)
          printed_by_chrome(page, printed)
          File.binread(printed)
        end
      end

      def chrome
        Pages.chrome_path.presence || ENV["CHROME_BIN"].presence
      end

      def printed_by_chrome(page, printed)
        _output, errors, _status = Open3.capture3(chrome.to_s, "--headless=new", "--disable-gpu", "--use-mock-keychain", "--password-store=basic", "--no-pdf-header-footer", "--print-to-pdf=#{printed}", "file://#{page}")
        raise PrintFailed, "Chrome at #{chrome} could not print the page: #{errors.strip}" unless File.size?(printed)
      rescue SystemCallError => error
        raise PrintFailed, "Chrome at #{chrome} could not be started: #{error.message}"
      end
    end
  end
end
