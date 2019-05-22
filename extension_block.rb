class ExtensionBlock
  def self.parse(stream)
    extension_blocks = []

    while stream.peek(1) == "\x21".b
      extension_blocks << parse_block(stream)
    end

    extension_blocks
  end

  # Extension blocks are indicated by the 21 byte
  # The format is:
  #
  #    Offset   Length   Contents
  #    0        1 byte   Extension Introducer (0x21)
  #    1        1 byte   Graphic Control Label (0xf9)
  #    2        1 byte   Block Size (0x04)
  #
  # The block size is the number of bytes that follow not including block
  # terminator (0x00)
  def self.parse_block(stream)
    ext_introducer = stream.read(1)
    label = stream.read(1)
    block_size_raw = stream.read(1)
    block_size = block_size_raw.unpack("C")[0]

    # TODO: Update this to switch on the block type
    new(
      ext_introducer + label + block_size_raw + stream.read(block_size + 1)
    )
  end

  attr_reader :bytes

  def initialize(bytes)
    @bytes = bytes
  end
end
