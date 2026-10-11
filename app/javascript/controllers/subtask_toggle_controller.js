import { Controller } from '@hotwired/stimulus'
import { savePreference } from 'lib/preferences'

// Lembra quais tarefas estão com as subtarefas abertas na tabela: o collapse do Bootstrap abre e
// recolhe, e a cada troca os ids das abertas vão para o cookie `expanded_tasks`, separados por ponto;
// o servidor já as renderiza assim.
export default class extends Controller {
  save(event) {
    const id = event.target.dataset.taskId
    if (!id) return

    const expanded = new Set(this.expandedIds())
    event.type === 'shown.bs.collapse' ? expanded.add(id) : expanded.delete(id)
    savePreference('expanded_tasks', [...expanded].join('.'))
  }

  expandedIds() {
    const cookie = document.cookie.split('; ').find(entry => entry.startsWith('expanded_tasks='))
    return cookie ? decodeURIComponent(cookie.split('=')[1]).split('.').filter(Boolean) : []
  }
}
