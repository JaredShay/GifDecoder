require 'forwardable'

require_relative 'binary_file_stream'
require_relative 'header'
require_relative 'extension_block'
require_relative 'frame'

class Gif
  extend Forwardable

  TRAILER = ";"

  attr_reader :extension_blocks

  def initialize(file_path)
    @stream = BinaryFileStream.from_path(file_path)

    begin
      @header = Header.parse(@stream)
      @extension_blocks = ExtensionBlock.parse(@stream)
    rescue => e
      @stream.close
      raise e
    end
  end

  def_delegators :@header,
    :signature,
    :version,
    :width,
    :height,
    :global_color_table_flag,
    :color_resolution,
    :sort_flag,
    :size_of_global_color_table,
    :background_color_index,
    :pixel_aspect_ratio,
    :global_color_table

  # Returns a `Frame` object or `nil` to indicate all frames have been parsed
  def get_frame
    return nil if @stream.eof?
    return nil if @stream.peek(1) == TRAILER

    begin
      Frame.parse(@stream, global_color_table)
    rescue => e
      @stream.close
      raise e
    end
  end
end

gif = Gif.new(File.join(File.expand_path("."), "GifSample2.gif"))

puts "signature: #{gif.signature.inspect}"
puts "version: #{gif.version}"
puts "width: #{gif.width}"
puts "height: #{gif.height}"
puts " - global_color_table_flag: #{gif.global_color_table_flag}"
puts " - color_resolution: #{gif.color_resolution}"
puts " - sort_flag: #{gif.sort_flag}"
puts " - size_of_global_color_table: #{gif.size_of_global_color_table}"
puts "background_color_index: #{gif.background_color_index}"
puts "pixel_aspect_ratio: #{gif.pixel_aspect_ratio}"
puts "global_color_table: #{gif.global_color_table}"
puts "extension_blocks: #{gif.extension_blocks}"

puts gif.get_frame.inspect
puts gif.get_frame.inspect
