class ListsController < ApplicationController
  before_action :remember_sort, only: :show

  service_actions :index, :show, :new, :create, :edit, :update, :destroy

  private

  def index_redirect
    redirect_to list_path(@list) if @list
  end

  # Com erro, o formulário volta no modal com a mensagem no campo.
  def create_redirect
    @error ? render(:new, status: :unprocessable_content) : redirect_to(list_path(@list))
  end

  def update_redirect
    @error ? render(:edit, status: :unprocessable_content) : redirect_to(list_path(@list))
  end

  def destroy_redirect
    redirect_to root_path, status: :see_other
  end

  # Ordem escolhida no menu "Ordenar por", lembrada por lista em cookie.
  def remember_sort
    return unless Core::Domain::TaskSort.valid?(params[:sort])

    cookies["list_sort_#{params[:id]}"] = { value: params[:sort], expires: 1.year }
  end
end
