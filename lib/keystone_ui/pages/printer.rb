# frozen_string_literal: true

require "open3"
require "tmpdir"
require "keystone_ui/pages"

module KeystoneUi
  module Pages
    module Printer
      module_function

      def pdf(html)
        Dir.mktmpdir do |folder|
          page = File.join(folder, "page.html")
          printed = File.join(folder, "page.pdf")
          File.write(page, html)
          Open3.capture3(Pages.chrome_path, "--headless=new", "--disable-gpu", "--no-pdf-header-footer", "--print-to-pdf=#{printed}", "file://#{page}")
          File.binread(printed)
        end
      end
    end
  end
end
