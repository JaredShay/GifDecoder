class Frame
  LOCAL_COLOR_TABLE_FLAG_MASK = 0b1000_0000
  INTERLACE_FLAG_MASK = 0b0100_0000
  SORT_FLAG_MASK = 0b0010_0000
  SIZE_OF_LOCAL_COLOR_TABLE_MASK = 0b0000_0111

  def self.parse(stream, global_color_table = nil)
    image_separator = stream.read(1)
    puts image_separator.inspect

    img_left_pos = stream.read(2).unpack('v')[0]
    img_right_pos = stream.read(2).unpack('v')[0]
    img_width = stream.read(2).unpack('v')[0]
    img_height = stream.read(2).unpack('v')[0]

    # bit 0:    Local Color Table Flag (LCTF)
    # bit 1:    Interlace Flag
    # bit 2:    Sort Flag
    # bit 2..3: Reserved
    # bit 4..7: Size of Local Color Table: 2^(1+n)
    packed_byte = stream.read(1).unpack('C*')[0]
    local_color_table_flag = packed_byte & LOCAL_COLOR_TABLE_FLAG_MASK != 0
    interlace_flag = packed_byte & INTERLACE_FLAG_MASK != 0
    sort_flag = packed_byte & SORT_FLAG_MASK != 0

    if local_color_table_flag
      size_of_local_color_table = 2 ** (1 + packed_byte & SIZE_OF_LOCAL_COLOR_TABLE_MASK)
      # TODO: Find test case for this
      local_color_table = stream.read(size_of_local_color_table)
    else
      color_table = global_color_table
      size_of_local_color_table = 0
    end

    lzw_minimum_code_size = stream.read(1).unpack('C')[0]

    puts "img_left_pos: #{img_left_pos.inspect}"
    puts "img_right_post: #{img_right_pos.inspect}"
    puts "img_width: #{img_width.inspect}"
    puts "img_height: #{img_height.inspect}"
    puts "local_color_table_flag: #{local_color_table_flag.inspect}"
    puts "interlace_flag: #{interlace_flag.inspect}"
    puts "sort_flag: #{sort_flag.inspect}"
    puts "size_of_local_color_table: #{size_of_local_color_table.inspect}"
    puts "lzw_minimum_code_size: #{lzw_minimum_code_size.inspect}"

    code_table = {}
    color_table.each.with_index do |_, i|
      code_table[i] = [i]
    end

    # clear code & end of information code
    code_table[2 ** lzw_minimum_code_size] = :clear_code
    code_table[2 ** lzw_minimum_code_size + 1] = :eoi_code
    next_open_code_table_index = 2 ** lzw_minimum_code_size + 2

    current_code_size = lzw_minimum_code_size
    index_stream = []
    code_stream = []

    # Next byte indicates how many more bytes need to be read
    bytes_remaining_in_frame = stream.read(1).unpack('C')[0]
    remaining_image_data = stream.read(bytes_remaining_in_frame)

    # Only doing this so I can easily verify what I'm doing visually
    str_representing_bits = remaining_image_data
      .unpack('C*')
      .map { |byte| sprintf("%.8b", byte).reverse }
      .join('')

    chars_in_code = 2 ** (current_code_size - 1) + 1
    puts "code size: #{chars_in_code}"
    code = nil
    code_prev = nil

    while !(code = str_representing_bits.slice!(0, chars_in_code)).empty?
      parsed_code = code.reverse.to_i(2)
      break if code_table[parsed_code] == :eoi_code

      puts "handling code: #{code.reverse}:#{parsed_code}"

      # this should actually re-initialize the table. Not handling that for now
      # so this is just to burn off the first code from the stream
      next if code_table[parsed_code] == :clear_code

      if code_table.key?(parsed_code)
        index_stream << code_table[parsed_code]

        # guard against doing this for the first code
        if !code_prev.nil?
          new_entry = code_table[code_prev] + [code_table[parsed_code][0]]
          code_table[next_open_code_table_index] = new_entry
          next_open_code_table_index += 1
        end
      else
        # code is not in the table
        new_entry = code_table[code_prev] + [code_table[code_prev][0]]
        code_table[next_open_code_table_index] = new_entry
        index_stream << new_entry
        next_open_code_table_index += 1
      end

      code_prev = parsed_code

      if next_open_code_table_index == 2 ** chars_in_code
        chars_in_code += 1
      end
    end

    zero_end_byte = stream.read(1)
    new(color_table, index_stream.flatten)
  end

  def initialize(color_table, indexes)
    @color_table = color_table
    @indexes = indexes
  end

  def pixels
    @indexes.map { |i| color_table[i] }.each
  end
end
