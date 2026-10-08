import { Controller } from '@hotwired/stimulus'
import { patch } from '@rails/request.js'
import Sortable from 'sortablejs'

// Arrastar na tabela da lista, pela alça de cada linha. Solta em outra seção, a tarefa ganha a
// prioridade ou o prazo dela; na ordem personalizada, também fica entre os vizinhos onde foi solta.
export default class extends Controller {
  static targets = ['section']
  static values = { group: String, reorder: Boolean }

  connect() {
    this.sortables = this.sectionTargets.map(section =>
      Sortable.create(section, {
        group: { name: 'tasks', put: section.dataset.droppable === 'true' },
        sort: this.reorderValue,
        handle: '.task-drag-handle',
        draggable: '[data-id]',
        animation: 150,
        onEnd: event => this.move(event)
      })
    )
  }

  disconnect() {
    this.sortables.forEach(sortable => sortable.destroy())
  }

  async move(event) {
    const changedSection = event.from !== event.to
    if (!changedSection && event.oldDraggableIndex === event.newDraggableIndex) return

    const body = { group: this.groupValue }
    if (changedSection) body.section = event.to.dataset.section
    if (this.reorderValue) {
      body.previous_id = this.neighbor(event.item, 'previousElementSibling')
      body.following_id = this.neighbor(event.item, 'nextElementSibling')
    }

    const response = await patch(`/tasks/${event.item.dataset.id}/move`, { body })
    // Recusado, volta ao estado gravado; mudar de seção muda a prioridade ou o prazo, a contagem das
    // seções e, fora da ordem personalizada, a posição, e a página volta do servidor com tudo isso.
    if (!response.ok || changedSection) Turbo.visit(window.location.href)
  }

  neighbor(item, direction) {
    let sibling = item[direction]
    while (sibling && !sibling.dataset.id) sibling = sibling[direction]
    return sibling?.dataset.id
  }
}
