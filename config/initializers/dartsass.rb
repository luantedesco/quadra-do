# O Bootstrap 5.3 ainda usa @import e funções de cor antigas do Sass, e os avisos de depreciação dele
# encobririam os do SCSS do app.
Rails.application.config.dartsass.build_options << "--quiet-deps"
# O SCSS do Hyper, copiado do template, usa @import (único jeito de customizar o Bootstrap 5.3) e
# funções globais e de cor que o Sass vai remover; a migração vem junto com a do Bootstrap 6.
Rails.application.config.dartsass.build_options << "--silence-deprecation=import,global-builtin,color-functions"
