import { Controller } from '@hotwired/stimulus'
import { patch } from '@rails/request.js'
import Sortable from 'sortablejs'

const PANEL_LIST = '#tasks-panel-lists li[data-id]'

// Arrastar na tabela da lista, pela alça de cada linha. Solta sobre outra lista do painel, a tarefa vai
// para ela; solta em outra seção, ganha a prioridade ou o prazo dela; na ordem personalizada, também
// fica entre os vizinhos onde foi solta.
export default class extends Controller {
  static targets = ['section']
  static values = { group: String, reorder: Boolean, list: String }

  connect() {
    this.track = this.track.bind(this)
    this.sortables = this.sectionTargets.map(section =>
      Sortable.create(section, {
        group: { name: 'tasks', put: section.dataset.droppable === 'true' },
        sort: this.reorderValue,
        handle: '.task-drag-handle',
        draggable: '[data-id]',
        animation: 150,
        onStart: () => this.startTracking(),
        onEnd: event => this.drop(event)
      })
    )
  }

  disconnect() {
    this.stopTracking()
    this.sortables.forEach(sortable => sortable.destroy())
  }

  // Enquanto arrasta, guarda onde está o ponteiro e destaca a lista do painel debaixo dele.
  startTracking() {
    document.addEventListener('dragover', this.track)
    document.addEventListener('pointermove', this.track)
  }

  stopTracking() {
    document.removeEventListener('dragover', this.track)
    document.removeEventListener('pointermove', this.track)
    this.highlight(null)
  }

  track(event) {
    this.point = { x: event.clientX, y: event.clientY }
    this.highlight(this.panelListAt(this.point))
  }

  highlight(target) {
    if (this.highlighted === target) return
    this.highlighted?.classList.remove('drop-target')
    target?.classList.add('drop-target')
    this.highlighted = target
  }

  panelListAt(point) {
    if (!point) return null
    const list = document.elementFromPoint(point.x, point.y)?.closest(PANEL_LIST)
    return list && list.dataset.id !== this.listValue ? list : null
  }

  async drop(event) {
    const panelList = this.panelListAt(this.point)
    this.stopTracking()
    this.point = null

    if (panelList) return this.moveToList(event.item.dataset.id, panelList.dataset.id)
    return this.move(event)
  }

  // A resposta é o refresh da página, que tira a tarefa da tabela.
  async moveToList(taskId, listId) {
    const response = await patch(`/tasks/${taskId}/move_to_list`, {
      body: { task: { list_id: listId } },
      responseKind: 'turbo-stream'
    })
    if (!response.ok) Turbo.visit(window.location.href)
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
