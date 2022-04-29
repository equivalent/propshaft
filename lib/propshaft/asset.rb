require "digest/sha1"
require "action_dispatch/http/mime_type"

class Propshaft::Asset
  attr_reader :path, :logical_path, :version

  def initialize(path, logical_path:, version: nil)
    @path, @logical_path, @version = path, Pathname.new(logical_path), version
  end

  def content
    File.binread(path)
  end

  def modified_at
    File.mtime(path)
  end

  def content_type
    Mime::Type.lookup_by_extension(logical_path.extname.from(1))
  end

  def length
    content.size
  end

  def digest
    @digest ||= Digest::SHA1.hexdigest(digest_source)
  end

  def digest_source
    source = [content]
    source << modified_at.to_i if Rails.application.assets.resolver.tracks_modifications?
    source << version
    source.join
  end

  def digested_path
    if already_digested?
      logical_path
    else
      logical_path.sub(/\.(\w+)$/) { |ext| "-#{digest}#{ext}" }
    end
  end

  def fresh?(digest)
    self.digest == digest || already_digested?
  end

  def ==(other_asset)
    logical_path.hash == other_asset.logical_path.hash
  end

  private
    def already_digested?
      logical_path.to_s =~ /-([0-9a-zA-Z]{7,128})\.digested/
    end
end
