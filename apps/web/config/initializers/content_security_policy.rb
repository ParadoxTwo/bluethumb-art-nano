# frozen_string_literal: true

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
