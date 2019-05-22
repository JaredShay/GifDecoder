# Simple wrapper around a file stream. Most methods are just delegated to the
# underlying io interface. This adds a peek(n) call and is more explicit in how
# it reads chunks into memory.
class BinaryFileStream
  CHUNK_SIZE = 1024

  def self.from_path(file_path)
    new(file_path)
  end

  def initialize(file_path)
    @stream = File.open(file_path, 'r')
    @buffer = ''
  end

  def pos=(n)
    @stream.pos = n
  end

  def pos
    @stream.pos
  end

  def read(n)
    write_to_buffer if @buffer.length < n

    @buffer.slice!(0, n)
  end

  def peek(n)
    write_to_buffer if @buffer.length < n

    @buffer.slice(0, n)
  end

  def eof?
    @stream.eof? && @buffer.empty?
  end

  def close
    @stream.close
  end

  private

  def write_to_buffer
    @buffer << @stream.read(CHUNK_SIZE) unless @stream.eof?
  end
end
