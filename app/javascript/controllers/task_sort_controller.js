import { Controller } from '@hotwired/stimulus'
import { patch } from '@rails/request.js'
import Sortable from 'sortablejs'

const PANEL_LIST = '#tasks-panel-lists li[data-id]'

// Arrastar na tabela da lista, pela alça de cada linha. Solta sobre outra lista do painel, a tarefa vai
// para ela; sobre o meio de outra linha, vira filha dela; em outro bloco, ganha o pai dele (o bloco das
// tarefas de topo não tem pai) e, em outra seção, a prioridade ou o prazo dela; na ordem
// personalizada, também fica entre os vizinhos onde foi solta.
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
        fallbackOnBody: true,
        swapThreshold: 0.65,
        onStart: event => this.startTracking(event.item),
        onEnd: event => this.drop(event)
      })
    )
  }

  disconnect() {
    this.stopTracking()
    this.sortables.forEach(sortable => sortable.destroy())
  }

  // Enquanto arrasta, guarda onde está o ponteiro e destaca o destino debaixo dele.
  startTracking(item) {
    this.dragged = item
    document.addEventListener('dragover', this.track)
    document.addEventListener('pointermove', this.track)
  }

  stopTracking() {
    document.removeEventListener('dragover', this.track)
    document.removeEventListener('pointermove', this.track)
    this.highlight('panel', null)
    this.highlight('nest', null)
    this.dragged = null
  }

  track(event) {
    this.point = { x: event.clientX, y: event.clientY }
    this.highlight('panel', this.panelListAt(this.point), 'drop-target')
    this.highlight('nest', this.nestTargetAt(this.point), 'nest-target')
  }

  highlight(kind, target, className) {
    const current = this.highlighted?.[kind]
    if (current === target) return
    current?.classList.remove('drop-target', 'nest-target')
    target?.classList.add(className)
    this.highlighted = { ...this.highlighted, [kind]: target }
  }

  panelListAt(point) {
    if (!point) return null
    const list = document.elementFromPoint(point.x, point.y)?.closest(PANEL_LIST)
    return list && list.dataset.id !== this.listValue ? list : null
  }

  // A linha de outra tarefa com o ponteiro na faixa do meio; perto das bordas, vale o reordenar.
  nestTargetAt(point) {
    if (!point || !this.dragged) return null
    const node = document.elementFromPoint(point.x, point.y)?.closest('.task-node')
    if (!node || !this.element.contains(node) || this.dragged.contains(node)) return null

    const row = node.querySelector(':scope > .row').getBoundingClientRect()
    const middle = point.y > row.top + row.height * 0.25 && point.y < row.bottom - row.height * 0.25
    return middle ? node : null
  }

  async drop(event) {
    const nestTarget = this.nestTargetAt(this.point)
    const panelList = this.panelListAt(this.point)
    this.stopTracking()
    this.point = null

    if (nestTarget) return this.send(event.item.dataset.id, { parent_id: nestTarget.dataset.id }, true)
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

  move(event) {
    const changedBlock = event.from !== event.to
    if (!changedBlock && event.oldDraggableIndex === event.newDraggableIndex) return

    const body = { group: this.groupValue }
    if (changedBlock) {
      body.parent_id = event.to.dataset.parentId
      if (event.to.dataset.section && event.to.dataset.section !== event.from.dataset.section) body.section = event.to.dataset.section
    }
    if (this.reorderValue) {
      body.previous_id = this.neighbor(event.item, 'previousElementSibling')
      body.following_id = this.neighbor(event.item, 'nextElementSibling')
    }

    return this.send(event.item.dataset.id, body, changedBlock)
  }

  // Recusado, volta ao estado gravado; mudar de bloco muda o pai, a prioridade ou o prazo, as setas e
  // as contagens, e a página volta do servidor com tudo isso.
  async send(taskId, body, reload) {
    const response = await patch(`/tasks/${taskId}/move`, { body: { group: this.groupValue, ...body } })
    if (!response.ok || reload) Turbo.visit(window.location.href)
  }

  neighbor(item, direction) {
    let sibling = item[direction]
    while (sibling && !sibling.dataset.id) sibling = sibling[direction]
    return sibling?.dataset.id
  }
}
