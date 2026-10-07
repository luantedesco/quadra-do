class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  # Cada action chama o service Web::<Controller>::<Action>Service e expõe a resposta à view.
  def self.service_actions(*actions)
    actions.each do |action|
      define_method(action) do
        service = "Web::#{controller_name.camelize}::#{action.to_s.camelize}Service".constantize
        respond_attempt(service.new(params:).call)
      end
    end
  end

  private

  # Cada chave do Hash do service vira variável da view (@instance, @error...).
  def respond_attempt(response)
    response.each { |key, value| instance_variable_set("@#{key}", value) }
  end
end
