# frozen_string_literal: true

require "net/http"

class PaletteProxyController < ApplicationController
  skip_forgery_protection

  def forward
    target = URI.join(palette_base_url, "/#{params[:path]}")
    target.query = request.query_string if request.query_string.present?

    http = Net::HTTP.new(target.host, target.port)
    http.use_ssl = target.scheme == "https"
    http.open_timeout = PaletteClient::OPEN_TIMEOUT
    http.read_timeout = 30

    proxy_request = build_proxy_request(target)
    response = http.request(proxy_request)

    # This endpoint is a JSON API to the browser, so an HTML error page from
    # whatever is standing in front of the service must not be handed through
    # as though the service had spoken.
    unless json_response?(response)
      return render json: {
        error: {
          code: "bad_gateway",
          message: "Palette service returned #{response.code} with a non-JSON body"
        }
      }, status: :bad_gateway
    end

    render plain: response.body, status: response.code.to_i, content_type: response.content_type
  rescue Errno::ECONNREFUSED, Errno::ECONNRESET, SocketError, Net::OpenTimeout, Net::ReadTimeout
    render json: { error: { code: "service_unavailable", message: "Palette service unavailable" } }, status: :service_unavailable
  end

  private

  def json_response?(response)
    return true if response.body.blank?

    response.content_type.to_s.include?("json")
  end

  def palette_base_url
    ENV.fetch("PALETTE_SERVICE_URL", "http://localhost:9292")
  end

  def build_proxy_request(target)
    klass = proxy_request_class
    req = klass.new(target)
    req["Accept"] = request.headers["Accept"] if request.headers["Accept"]
    req["Content-Type"] = request.content_type if request.content_type.present?
    req.body = request.raw_post if request.raw_post.present?
    req
  end

  def proxy_request_class
    {
      "GET" => Net::HTTP::Get,
      "POST" => Net::HTTP::Post,
      "PUT" => Net::HTTP::Put,
      "PATCH" => Net::HTTP::Patch,
      "DELETE" => Net::HTTP::Delete
    }.fetch(request.request_method)
  end
end
