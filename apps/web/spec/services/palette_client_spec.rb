# frozen_string_literal: true

require "rails_helper"
require "webmock/rspec"
require "tmpdir"

RSpec.describe PaletteClient do
  before { WebMock.disable_net_connect! }

  it "returns health status" do
    stub_request(:get, "http://localhost:9292/health")
      .to_return(status: 200, body: { status: "ok" }.to_json, headers: { "Content-Type" => "application/json" })

    expect(described_class.new.health).to eq("status" => "ok")
  end

  it "returns similar artworks" do
    stub_request(:get, "http://localhost:9292/colour/similar/5")
      .to_return(
        status: 200,
        body: { artworks: [{ id: 9, distance: 0.2 }] }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    expect(described_class.new.similar(5)).to eq("artworks" => [{ "id" => 9, "distance" => 0.2 }])
  end

  it "extracts palette data for an artwork" do
    stub_request(:post, "http://localhost:9292/colour/extract")
      .with(body: { artwork_id: 3, force: true }.to_json)
      .to_return(status: 200, body: { status: "ok" }.to_json, headers: { "Content-Type" => "application/json" })

    expect(described_class.new.extract(artwork_id: 3, force: true)).to eq("status" => "ok")
  end

  it "speaks TLS when the service URL is https" do
    stub_request(:get, "https://palette.example.test/health")
      .to_return(status: 200, body: { status: "ok" }.to_json, headers: { "Content-Type" => "application/json" })

    client = described_class.new(base_url: "https://palette.example.test")

    expect(client.health).to eq("status" => "ok")
  end

  it "raises a palette error when the service does not answer in time" do
    stub_request(:get, "http://localhost:9292/colour/similar/2").to_timeout

    expect { described_class.new.similar(2) }
      .to raise_error(PaletteClient::Error, /unavailable/)
  end

  it "uploads the image when one is given, so a service with no shared disk can still extract" do
    png = File.join(Dir.tmpdir, "client-upload-#{Process.pid}.png")
    File.binwrite(png, "\x89PNG\r\n\x1a\n binary \xff\xfe bytes")

    stub_request(:post, "http://localhost:9292/colour/extract")
      .to_return(status: 200, body: { artwork_id: 7, source: "upload" }.to_json,
                 headers: { "Content-Type" => "application/json" })

    result = described_class.new.extract(
      artwork_id: 7, force: true,
      image: { path: png, content_type: "image/png", filename: "seven.png" }
    )

    expect(result).to eq("artwork_id" => 7, "source" => "upload")
    expect(
      a_request(:post, "http://localhost:9292/colour/extract").with { |req|
        req.headers["Content-Type"].start_with?("multipart/form-data; boundary=") &&
          req.body.include?("name=\"artwork_id\"") && req.body.include?("7") &&
          req.body.include?("filename=\"seven.png\"") && req.body.include?("Content-Type: image/png")
      }
    ).to have_been_made
  ensure
    File.delete(png) if png && File.exist?(png)
  end

  it "posts multipart over TLS when the service URL is https" do
    png = File.join(Dir.tmpdir, "client-tls-#{Process.pid}.png")
    File.binwrite(png, "\x89PNG\r\n\x1a\n bytes")

    stub_request(:post, "https://palette.example.test/colour/extract")
      .to_return(status: 200, body: {}.to_json, headers: { "Content-Type" => "application/json" })

    described_class.new(base_url: "https://palette.example.test")
                   .extract(artwork_id: 1, image: { path: png, content_type: "image/png" })

    expect(a_request(:post, "https://palette.example.test/colour/extract")).to have_been_made
  ensure
    File.delete(png) if png && File.exist?(png)
  end

  it "raises with palette error message on failure" do
    stub_request(:get, "http://localhost:9292/colour/similar/1")
      .to_return(
        status: 422,
        body: { error: { code: "missing_palette", message: "No palette data" } }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    expect { described_class.new.similar(1) }.to raise_error(PaletteClient::Error, "No palette data")
  end

  it "posts a room photo as multipart and returns ranked artworks" do
    stub_request(:post, "http://localhost:9292/colour/match-room")
      .to_return(
        status: 200,
        body: { artworks: [{ id: 2, distance: 1.5 }], palette: { hue_family: "blue" } }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    file = Tempfile.new(["room", ".png"])
    file.write("png-bytes")
    file.rewind
    upload = Rack::Test::UploadedFile.new(file.path, "image/png", original_filename: "room.png")

    expect(described_class.new.match_room(upload)).to include(
      "artworks" => [{ "id" => 2, "distance" => 1.5 }]
    )
  ensure
    file.close!
  end
end
