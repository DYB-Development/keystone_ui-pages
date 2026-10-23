# frozen_string_literal: true

class ProductsController < ApplicationController
  layout -> { %w[tokenless turbo].include?(params[:layout]) ? params[:layout] : "application" }

  def show
    @page = KeystoneUi::Pages::Page.find_by!(slug: params[:slug])
  end
end
