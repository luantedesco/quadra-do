module Core
  module Domain
    # Ordem das tarefas nas visões da lista (menu "Ordenar por"); "manual" é a ordem do arrasto, e
    # valor desconhecido cai nela.
    class TaskSort
      ORDERS = {
        "manual" => { position: :asc, created_at: :asc },
        "deadline" => Arel.sql("tasks.deadline ASC NULLS LAST, tasks.position ASC"),
        "priority" => { priority: :desc, position: :asc },
        "title" => Arel.sql("LOWER(tasks.title) ASC"),
        "created" => { created_at: :desc }
      }.freeze
      DEFAULT = "manual"

      attr_reader :key

      def self.keys
        ORDERS.keys
      end

      def self.valid?(key)
        ORDERS.key?(key.to_s)
      end

      def initialize(key)
        @key = self.class.valid?(key) ? key.to_s : DEFAULT
      end

      def order
        ORDERS.fetch(key)
      end

      def manual?
        key == DEFAULT
      end

      def to_s
        key
      end
    end
  end
end
