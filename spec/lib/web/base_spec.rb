require "rails_helper"

RSpec.describe Web::Base do
  def service_class(&block)
    Class.new(described_class) do
      attr_accessor :steps

      private

      def set_instance
        (self.steps ||= []) << :set_instance
        self.instance = params[:instance]
      end

      def validate!
        steps << :validate!
      end

      def run!
        steps << :run!
      end

      class_eval(&block) if block
    end
  end

  it "roda set_instance, validate! e run! nessa ordem e devolve a instância sem erro" do
    service = service_class.new(params: { instance: "registro" })

    expect(service.call).to eq(instance: "registro", error: nil)
    expect(service.steps).to eq(%i[set_instance validate! run!])
  end

  it "devolve o erro de regra como mensagem, sem rodar o run!" do
    service = service_class do
      define_method(:validate!) { raise Core::Errors::ValidationError, "Título repetido" }
    end.new(params: { instance: "registro" })

    expect(service.call).to eq(instance: "registro", error: "Título repetido")
    expect(service.steps).to eq(%i[set_instance])
  end

  it "deixa estourar o erro que não é de regra" do
    service = service_class do
      define_method(:run!) { raise ArgumentError, "bug" }
    end.new(params: {})

    expect { service.call }.to raise_error(ArgumentError, "bug")
  end
end
