# frozen_string_literal: true

require "cgi"
require "net/http"
require "openssl"
require "securerandom"

class PaletteClient
  class Error < StandardError; end

  # Short on purpose. The artwork page calls this synchronously, so a palette
  # service that is down or waking from a cold start must degrade the page in
  # a couple of seconds, not hang it for Net::HTTP's default sixty.
  OPEN_TIMEOUT = Float(ENV.fetch("PALETTE_OPEN_TIMEOUT", 2))
  READ_TIMEOUT = Float(ENV.fetch("PALETTE_READ_TIMEOUT", 8))

  NETWORK_ERRORS = [
    Errno::ECONNREFUSED, Errno::ECONNRESET, SocketError,
    Net::OpenTimeout, Net::ReadTimeout, OpenSSL::SSL::SSLError
  ].freeze

  def initialize(base_url: ENV.fetch("PALETTE_SERVICE_URL", "http://localhost:9292"))
    @base_url = base_url
  end

  def health
    get("/health")
  end

  # Naming the artwork asks the service to find the file on its own disk.
  # Passing an image sends the bytes instead, which is the only thing that
  # works when the two services do not share a filesystem.
  def extract(artwork_id:, force: false, image: nil)
    return post("/colour/extract", body: { artwork_id: artwork_id, force: force }) if image.nil?

    post_multipart(
      "/colour/extract",
      file: image,
      fields: { "artwork_id" => artwork_id.to_s, "force" => force.to_s }
    )
  end

  # hex ranks against a colour the buyer picked; omitted, the service ranks
  # against the artwork's own palette centroid.
  def similar(artwork_id, hex: nil)
    path = "/colour/similar/#{artwork_id}"
    path = "#{path}?hex=#{CGI.escape(hex.to_s.delete_prefix('#'))}" if hex.present?
    get(path)
  end

  def match_room(upload)
    post_multipart("/colour/match-room", file: upload)
  end

  private

  # Went through the plain request path before, which meant no TLS: against an
  # https service URL that fails outright rather than degrading.
  def post_multipart(path, file:, fields: {})
    uri = URI.join("#{@base_url}/", path.sub(%r{\A/}, ""))
    request = Net::HTTP::Post.new(uri)
    request["Accept"] = "application/json"
    boundary, body = multipart_body(file, fields)
    request["Content-Type"] = "multipart/form-data; boundary=#{boundary}"
    request.body = body
    parse_response(build_http(uri).request(request))
  rescue *NETWORK_ERRORS => e
    raise Error, "Palette service unavailable: #{e.message}"
  end

  def build_http(uri)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = uri.scheme == "https"
    http.open_timeout = OPEN_TIMEOUT
    http.read_timeout = READ_TIMEOUT
    http
  end

  # Built on a binary string: appending PNG bytes to a UTF-8 buffer is only
  # safe while everything before it is ASCII, which is a trap waiting for a
  # non-ASCII filename.
  def multipart_body(file, fields = {})
    boundary = "----RubyFormBoundary#{SecureRandom.hex(16)}"
    path, content_type, filename = file_parts(file)

    body = "".b
    fields.each do |name, value|
      body << "--#{boundary}\r\n"
      body << "Content-Disposition: form-data; name=\"#{name}\"\r\n\r\n"
      body << value.to_s
      body << "\r\n"
    end
    body << "--#{boundary}\r\n"
    body << "Content-Disposition: form-data; name=\"image\"; filename=\"#{filename}\"\r\n"
    body << "Content-Type: #{content_type}\r\n\r\n"
    body << File.binread(path)
    body << "\r\n--#{boundary}--\r\n"
    [boundary, body]
  end

  # Accepts an uploaded file from a controller, or a plain hash from a batch
  # job that already has the bytes on disk.
  def file_parts(file)
    if file.is_a?(Hash)
      path = file[:path]
      [path, file[:content_type].presence || "image/jpeg", file[:filename].presence || File.basename(path)]
    else
      path = file.respond_to?(:tempfile) ? file.tempfile.path : file.path
      content_type = file.respond_to?(:content_type) ? file.content_type.to_s : ""
      filename = file.respond_to?(:original_filename) ? file.original_filename : File.basename(path)
      [path, content_type.presence || "image/jpeg", filename]
    end
  end

  def get(path)
    request(:get, path)
  end

  def post(path, body: nil)
    request(:post, path, body: body)
  end

  def request(method, path, body: nil)
    uri = URI.join("#{@base_url}/", path.sub(%r{\A/}, ""))
    req = build_request(method, uri, body)
    response = build_http(uri).request(req)
    parse_response(response)
  rescue *NETWORK_ERRORS => e
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
    body = parse_body(response)
    return body if response.is_a?(Net::HTTPSuccess)

    error = body["error"]
    message = error.is_a?(Hash) ? error["message"] : error
    raise Error, message.presence || "Palette service error (#{response.code})"
  end

  # Not everything that answers is the palette service. A proxy in front of it
  # - Render's edge while a free instance wakes, which can take half a minute -
  # replies with an HTML error page. Parsing that raised JSON::ParserError,
  # which is not a PaletteClient::Error, so it went straight past every rescue
  # and turned a sleeping colour service into a 500 on the artwork page.
  def parse_body(response)
    return {} if response.body.blank?

    JSON.parse(response.body)
  rescue JSON::ParserError
    raise Error, "Palette service returned #{response.code} with a non-JSON body"
  end
end
