import { Controller } from '@hotwired/stimulus'

// Menu lateral do Hyper só com ícones (data-sidenav-size="condensed"); abaixo de 768px vira gaveta
// com backdrop, aberta pelo botão do canto.
export default class extends Controller {
  connect() {
    this.adjust()
  }

  disconnect() {
    this.close()
  }

  adjust() {
    if (window.innerWidth <= 767.98) {
      this.resize('full')
    } else {
      this.close()
      this.resize('condensed')
    }
  }

  toggle() {
    if (this.element.getAttribute('data-sidenav-size') === 'full') this.open()
  }

  open() {
    this.element.classList.add('sidebar-enable')
    this.backdrop = document.createElement('div')
    this.backdrop.className = 'offcanvas-backdrop fade show'
    this.backdrop.addEventListener('click', () => this.close())
    document.body.appendChild(this.backdrop)
  }

  close() {
    this.element.classList.remove('sidebar-enable')
    this.backdrop?.remove()
    this.backdrop = null
  }

  resize(size) {
    this.element.setAttribute('data-sidenav-size', size)
  }
}
