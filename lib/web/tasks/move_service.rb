module Web
  module Tasks
    # Arrastar na tabela da lista: solta em outro bloco, a tarefa ganha o pai dele (vazio é a tarefa de
    # topo); solta em outra seção, a prioridade ou o prazo dela; com os vizinhos (só na ordem
    # personalizada), é encaixada entre eles.
    class MoveService < Base
      private

      def validate!
        return if params[:section].blank? || section_attributes

        raise Core::Errors::ValidationError, I18n.t("tasks.move.not_droppable")
      end

      def run!
        instance.transaction do
          instance.update!(section_attributes) if section_attributes
          instance.nest_under!(new_parent) if params.key?(:parent_id)
          instance.move_beside!(previous: neighbor(:previous_id), following: neighbor(:following_id))
        end
      end

      def section_attributes
        return if params[:section].blank?

        @section_attributes ||= Core::Domain::TaskGroup.new(params[:group]).attributes_for(params[:section], instance)
      end

      def new_parent
        instance.list.tasks.actives.find(params[:parent_id]) if params[:parent_id].present?
      end

      def neighbor(key)
        instance.list.tasks.actives.find_by(id: params[key]) if params[key].present?
      end
    end
  end
end
