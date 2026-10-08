import { Controller } from '@hotwired/stimulus'
import { savePreference } from 'lib/preferences'

// Alterna o tema claro/escuro no <html>, guardado no cookie `theme`, que o servidor já renderiza.
export default class extends Controller {
  toggle() {
    const theme = this.element.getAttribute('data-bs-theme') === 'light' ? 'dark' : 'light'
    savePreference('theme', theme)

    // Sem transição durante a troca; ler um estilo calculado aplica o tema novo antes de religá-las.
    this.element.classList.add('theme-switching')
    this.element.setAttribute('data-bs-theme', theme)
    this.element.setAttribute('data-menu-color', theme)
    window.getComputedStyle(this.element).color
    this.element.classList.remove('theme-switching')

    const icon = document.getElementById('theme-icon-toggle')
    if (!icon) return

    const dark = theme === 'dark'
    icon.classList.replace(dark ? 'ri-moon-line' : 'ri-sun-line', dark ? 'ri-sun-line' : 'ri-moon-line')
  }
}
