// Grava uma preferência do usuário em cookie por um ano; o servidor lê e já renderiza a página com ela.
export function savePreference(name, value) {
  document.cookie = `${name}=${value}; path=/; max-age=31536000; samesite=lax`
}
