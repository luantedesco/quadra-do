# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers"
pin_all_from "app/javascript/lib", under: "lib"

# Nome com .esm: a gem bootstrap (fonte do SCSS) também expõe um bootstrap.js, em UMD, nos asset paths.
pin "bootstrap", to: "bootstrap.esm.js" # @5.3.8
pin "jquery" # @3.7.1
pin "select2" # @4.1.0
pin "sortablejs" # @1.15.6

# Build empacotado do jsDelivr (+esm): o download pelo `bin/importmap pin` traz um índice
# que importa dezenas de módulos relativos não baixados.
pin "@popperjs/core", to: "@popperjs--core.js" # @2.11.8
