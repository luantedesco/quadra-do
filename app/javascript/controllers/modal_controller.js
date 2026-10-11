import { Controller } from '@hotwired/stimulus'

// Abre como modal do Bootstrap o conteúdo carregado no frame `modal`.
export default class extends Controller {
  connect() {
    this.modal = new bootstrap.Modal(this.element, { backdrop: 'static' })
    this.modal.show()
  }

  disconnect() {
    this.modal.hide()
  }
}
