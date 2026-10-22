# frozen_string_literal: true

module KeystoneUi
  module Pages
    module HostChecks
      private

      def owned_pages
        return Page.all unless KeystoneUi::Pages.owner_method

        Page.where(owner: page_owner)
      end

      def page_owner
        send(KeystoneUi::Pages.owner_method) if KeystoneUi::Pages.owner_method
      end

      def viewable?(page)
        return true unless KeystoneUi::Pages.view_check_method

        send(KeystoneUi::Pages.view_check_method, page)
      end

      def refuse
        return head(:not_found) unless KeystoneUi::Pages.refusal_method

        send(KeystoneUi::Pages.refusal_method)
      end
    end
  end
end
