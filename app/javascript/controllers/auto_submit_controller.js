import { Controller } from '@hotwired/stimulus'

// Envia o formulário assim que um campo muda.
export default class extends Controller {
  submit() {
    this.element.requestSubmit()
  }
}
