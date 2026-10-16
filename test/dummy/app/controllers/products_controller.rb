# frozen_string_literal: true

class ProductsController < ApplicationController
  def show
    @page = KeystoneUi::Pages::Page.find_by!(slug: params[:slug])
  end
end
