# O Bootstrap 5.3 ainda usa @import e funções de cor antigas do Sass, e os avisos de depreciação dele
# encobririam os do SCSS do app.
Rails.application.config.dartsass.build_options << "--quiet-deps"
