# frozen_string_literal: true

require "cgi"

class PaletteClient
  class Error < StandardError; end

  def initialize(base_url: ENV.fetch("PALETTE_SERVICE_URL", "http://localhost:9292"))
    @base_url = base_url
  end

  def health
    get("/health")
  end

  def extract(artwork_id:, force: false)
    post("/colour/extract", body: { artwork_id: artwork_id, force: force })
  end

  # hex ranks against a colour the buyer picked; omitted, the service ranks
  # against the artwork's own palette centroid.
  def similar(artwork_id, hex: nil)
    path = "/colour/similar/#{artwork_id}"
    path = "#{path}?hex=#{CGI.escape(hex.to_s.delete_prefix('#'))}" if hex.present?
    get(path)
  end

  private

  def get(path)
    request(:get, path)
  end

  def post(path, body: nil)
    request(:post, path, body: body)
  end

  def request(method, path, body: nil)
    uri = URI.join("#{@base_url}/", path.sub(%r{\A/}, ""))
    http = Net::HTTP.new(uri.host, uri.port)
    req = build_request(method, uri, body)
    response = http.request(req)
    parse_response(response)
  rescue Errno::ECONNREFUSED => e
    raise Error, "Palette service unavailable: #{e.message}"
  end

  def build_request(method, uri, body)
    klass = method == :get ? Net::HTTP::Get : Net::HTTP::Post
    req = klass.new(uri)
    req["Accept"] = "application/json"
    if body
      req["Content-Type"] = "application/json"
      req.body = body.to_json
    end
    req
  end

  def parse_response(response)
    body = response.body.present? ? JSON.parse(response.body) : {}
    return body if response.is_a?(Net::HTTPSuccess)

    error = body["error"]
    message = error.is_a?(Hash) ? error["message"] : error
    raise Error, message.presence || "Palette service error (#{response.code})"
  end
end
