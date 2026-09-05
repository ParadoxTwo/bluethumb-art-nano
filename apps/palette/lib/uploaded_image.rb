# frozen_string_literal: true

require "securerandom"
require "tmpdir"

# Normalises a Rack multipart upload and spills it to a temporary file.
#
# libvips reads from a path, so every action that accepts an uploaded image
# needs the same three steps: coerce whatever Rack handed us into a hash, write
# the bytes to disk, delete them afterwards. Extract and MatchRoom both do it.
module UploadedImage
  EXTENSIONS = { "image/png" => ".png", "image/webp" => ".webp" }.freeze
  DEFAULT_EXTENSION = ".jpg"

  module_function

  # Rack surfaces an upload either as a hash or as an UploadedFile-like object,
  # depending on the server and the test driver. Returns nil when there is no
  # usable image, which callers read as "no upload was sent".
  def normalise(image)
    return nil if image.nil?
    return image if image.is_a?(Hash) || image.respond_to?(:[])
    return nil unless image.respond_to?(:tempfile) || image.respond_to?(:path)

    {
      tempfile: image.respond_to?(:tempfile) ? image.tempfile : File.open(image.path),
      type: image.respond_to?(:content_type) ? image.content_type : nil,
      size: image.respond_to?(:size) ? image.size : nil,
      filename: image.respond_to?(:original_filename) ? image.original_filename : nil
    }
  end

  def persist(uploaded, prefix:)
    tempfile = uploaded[:tempfile] || uploaded["tempfile"]
    path = File.join(Dir.tmpdir, "#{prefix}-#{Process.pid}-#{SecureRandom.hex(8)}#{extension_for(uploaded)}")
    IO.copy_stream(tempfile, path)
    tempfile.rewind if tempfile.respond_to?(:rewind)
    path
  end

  def extension_for(uploaded)
    type = (uploaded[:type] || uploaded["type"]).to_s
    EXTENSIONS.fetch(type, DEFAULT_EXTENSION)
  end
end
