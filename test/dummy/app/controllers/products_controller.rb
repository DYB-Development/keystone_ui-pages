# frozen_string_literal: true

class ProductsController < ApplicationController
  layout -> { params[:layout] == "tokenless" ? "tokenless" : "application" }

  def show
    @page = KeystoneUi::Pages::Page.find_by!(slug: params[:slug])
  end
end
