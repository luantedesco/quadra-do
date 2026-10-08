module Core
  module Domain
    # Agrupamento da tabela da lista (menu "Agrupar por"): divide as tarefas, já ordenadas, em seções
    # numa ordem fixa, sem as vazias. Prazo compara pelo dia, no fuso da aplicação; valor desconhecido
    # cai em "none", uma seção só.
    class TaskGroup
      DEFAULT = "none"
      SECTIONS = {
        "deadline" => %w[overdue today tomorrow next_7_days later no_deadline],
        "priority" => %w[high medium low none]
      }.freeze

      attr_reader :key

      def self.keys
        [ DEFAULT, *SECTIONS.keys ]
      end

      def self.valid?(key)
        keys.include?(key.to_s)
      end

      def initialize(key)
        @key = self.class.valid?(key) ? key.to_s : DEFAULT
      end

      def none?
        key == DEFAULT
      end

      # Pares [seção, tarefas]; sem agrupamento, uma seção nil com todas.
      def sections(tasks)
        return [ [ nil, tasks.to_a ] ] if none?

        grouped = tasks.group_by { |task| section_of(task) }
        SECTIONS.fetch(key).filter_map { |section| [ section, grouped[section] ] if grouped[section] }
      end

      def to_s
        key
      end

      private

      def section_of(task)
        key == "priority" ? task.priority : deadline_section(task.deadline)
      end

      def deadline_section(deadline)
        return "no_deadline" unless deadline

        days = (deadline.in_time_zone.to_date - Date.current).to_i
        if days.negative? then "overdue"
        elsif days.zero? then "today"
        elsif days == 1 then "tomorrow"
        elsif days <= 7 then "next_7_days"
        else "later"
        end
      end
    end
  end
end
