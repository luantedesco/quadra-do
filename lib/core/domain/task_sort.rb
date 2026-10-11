module Core
  module Domain
    # Ordem das tarefas nas visões da lista (menu "Ordenar por"); "manual" é a ordem do arrasto, sem
    # direção, e valor desconhecido cai nela. As outras ordens vão na direção escolhida ou na padrão
    # delas, e tarefa sem prazo ou sem prioridade fica sempre no fim.
    class TaskSort
      DEFAULT = "manual"
      DIRECTIONS = { "deadline" => "asc", "priority" => "desc", "title" => "asc", "created" => "desc" }.freeze

      attr_reader :key, :direction

      def self.keys
        [ DEFAULT, *DIRECTIONS.keys ]
      end

      def self.valid?(key)
        keys.include?(key.to_s)
      end

      def self.valid_direction?(direction)
        %w[asc desc].include?(direction.to_s)
      end

      def initialize(key, direction = nil)
        @key = self.class.valid?(key) ? key.to_s : DEFAULT
        @direction = DIRECTIONS[@key] && (self.class.valid_direction?(direction) ? direction.to_s : DIRECTIONS[@key])
      end

      def order
        return { position: :asc, created_at: :asc } if manual?

        Arel.sql(case key
        when "deadline" then "tasks.deadline #{sql_direction} NULLS LAST, tasks.position ASC"
        when "priority" then "tasks.priority = 0 ASC, tasks.priority #{sql_direction}, tasks.position ASC"
        when "title" then "LOWER(tasks.title) #{sql_direction}, tasks.position ASC"
        when "created" then "tasks.created_at #{sql_direction}"
        end)
      end

      def manual?
        key == DEFAULT
      end

      def to_s
        key
      end

      private

      def sql_direction
        direction.upcase
      end
    end
  end
end
