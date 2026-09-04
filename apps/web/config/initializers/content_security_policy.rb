# frozen_string_literal: true

# importmap-rails boots via an inline module script (`import "application"`).
# Without a per-request nonce, script-src 'self' blocks it and Vue islands never
# mount — the server placeholder stays an empty div.
Rails.application.configure do
  config.content_security_policy_nonce_generator = ->(_request) { SecureRandom.base64(16) }
  config.content_security_policy_nonce_directives = %w[script-src]
end

Rails.application.config.content_security_policy do |policy|
  policy.default_src :self, :https
  policy.font_src    :self, :https, :data
  policy.img_src     :self, :https, :data, :blob
  policy.object_src  :none
  policy.script_src  :self, :https
  policy.style_src   :self, :https, :unsafe_inline

  if Rails.env.development?
    policy.connect_src :self, :https, "http://localhost:3000", "http://localhost:9292", "ws://localhost:3000"
  end
end
