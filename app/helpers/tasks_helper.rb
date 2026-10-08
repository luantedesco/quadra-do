module TasksHelper
  PRIORITY_BADGES = { "low" => "badge-info-lighten", "medium" => "badge-warning-lighten", "high" => "badge-danger-lighten" }.freeze

  # Badge da prioridade da tarefa; sem prioridade, nenhum.
  def priority_badge(task)
    return if task.priority_none?

    tag.span(t("tasks.priorities.#{task.priority}"), class: "badge #{PRIORITY_BADGES.fetch(task.priority)} p-1")
  end
end
