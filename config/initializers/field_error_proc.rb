# O formulário marca o erro com as classes do Bootstrap (is-invalid e invalid-feedback); o invólucro
# field_with_errors do Rails quebraria o seletor que mostra a mensagem.
Rails.application.config.action_view.field_error_proc = ->(html_tag, _instance) { html_tag }
