module Web
  # Uma action da interface: set_instance -> validate! -> run! -> set_response. A resposta é um Hash
  # que o controller expõe à view por respond_attempt; erro de regra ou de validação volta em `error`
  # em vez de estourar no controller.
  class Base
    attr_accessor :params, :cookies, :instance, :error

    def initialize(params:, cookies: {})
      self.params = params
      self.cookies = cookies
      self.instance = nil
      self.error = nil
    end

    def call
      set_instance
      validate!
      run!
      set_response
    rescue Core::Errors::Base => e
      error_response(e.message)
    rescue ActiveRecord::RecordInvalid => e
      error_response(e.record.errors.full_messages.to_sentence)
    end

    private

    # Registro apagado responde 404, como um que não existe.
    def set_instance
      self.instance = klass.actives.find(params[:id]) if klass && params[:id].present?
    end

    def klass
      nil
    end

    def validate!
      nil
    end

    def run!
      nil
    end

    def set_response
      { instance:, error: }
    end

    def error_response(message)
      self.error = message
      set_response
    end
  end
end
