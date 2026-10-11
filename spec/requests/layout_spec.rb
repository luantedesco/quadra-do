require "rails_helper"

RSpec.describe "Layout", type: :request do
  it "abre a tela dentro do menu de ícones, com o item marcado e o título dele" do
    get root_path

    assert_select "title", text: "Tarefas · Quadra Do"
    assert_select "html[data-sidenav-size=condensed]"
    assert_select ".leftside-menu .side-nav-link.active[title=Tarefas][href=?]", root_path
    assert_select ".page-title", text: "Tarefas"
  end

  it "carrega só o CSS compilado, sem os .css crus que ele já importa" do
    get root_path

    assert_select "link[rel=stylesheet]", count: 1
    assert_select "link[rel=stylesheet][href^='/assets/application-']"
  end

  it "liga o menu à gaveta do celular, com o botão que a abre e o que a fecha" do
    get root_path

    assert_select "html[data-controller~=sidebar][data-action*='resize@window->sidebar#adjust']"
    assert_select "button.sidebar-mobile-toggle[data-action='sidebar#toggle'][aria-label=Menu]"
    assert_select ".leftside-menu .button-close-fullsidebar[data-action='click->sidebar#close']"
  end

  it "põe o tema no pé do menu" do
    get root_path

    assert_select ".side-nav-bottom .side-nav-link", text: "Tema"
  end

  describe "tema" do
    it "abre no tema guardado no cookie, com o ícone para voltar ao claro" do
      cookies[:theme] = "dark"

      get root_path

      assert_select "html[data-bs-theme=dark][data-menu-color=dark][data-controller~=theme]"
      assert_select "#theme-icon-toggle.ri-sun-line"
    end

    it "abre no claro sem cookie ou com um valor que não é tema" do
      cookies[:theme] = "azul"

      get root_path

      assert_select "html[data-bs-theme=light][data-menu-color=light]"
      assert_select "#theme-icon-toggle.ri-moon-line"
    end
  end
end
