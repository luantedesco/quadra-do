class ListsController < ApplicationController
  service_actions :index, :show

  private

  def index_redirect
    redirect_to list_path(@list) if @list
  end
end
