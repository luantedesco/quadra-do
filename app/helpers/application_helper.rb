module ApplicationHelper
  # Itens do menu lateral (só ícones). Cada item fica ativo nas telas dos controllers listados em
  # `controllers`.
  def navigation_items
    [
      { label: Task.model_name.human(count: 2), path: root_path, icon: "ri-checkbox-circle-line", controllers: %w[lists] }
    ]
  end

  def navigation_item_active?(item)
    item[:controllers].include?(controller_name)
  end

  # Título da página: o que a view declarar em content_for(:page_title), ou o rótulo do item ativo do
  # menu.
  def page_title
    @page_title ||= content_for(:page_title).presence ||
      navigation_items.find { |item| navigation_item_active?(item) }&.dig(:label)
  end

  # Atributos que o Hyper lê no <html>: layout vertical, tema claro e menu só com ícones.
  def document_attributes
    tag.attributes(lang: I18n.locale, data: {
      layout: "vertical",
      bs_theme: "light",
      menu_color: "light",
      layout_mode: "fluid",
      layout_position: "fixed",
      sidenav_size: "condensed"
    })
  end
end
