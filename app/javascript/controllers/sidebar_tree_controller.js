import { Controller } from '@hotwired/stimulus'
import { patch } from '@rails/request.js'
import Sortable from 'sortablejs'

// Arrastar no painel de Tarefas: muda a ordem das listas e grava no servidor; se o servidor recusar,
// recarrega a página para voltar à ordem gravada.
export default class extends Controller {
  connect() {
    this.sortable = Sortable.create(this.element, {
      animation: 150,
      onEnd: event => this.move(event)
    })
  }

  disconnect() {
    this.sortable.destroy()
  }

  async move(event) {
    if (event.oldIndex === event.newIndex) return

    const response = await patch('/sidebar/move', {
      body: { id: event.item.dataset.id, index: event.newIndex }
    })

    if (!response.ok) Turbo.visit(window.location.href)
  }
}
