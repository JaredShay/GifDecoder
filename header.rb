class Header
  GLOBAL_COLOR_TABLE_FLAG_MASK = 0b1000_0000
  COLOR_RESOLUTION_MASK = 0b0111_0000
  SORT_FLAG_MASK = 0b0000_1000
  SIZE_OF_GLOBAL_COLOR_TABLE_MASK = 0b0000_0111

  def self.parse(stream)
    new(stream)
  end

  attr_reader :signature,
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

  def initialize(stream)
    stream.pos = 0
    bytes = stream.read(13)

    @signature = bytes[0..2]
    @version = bytes[3..5]
    @width = bytes[6..7].unpack('v')[0]
    @height = bytes[8..9].unpack('v')[0]

    packed_field = bytes[10].unpack('C*')[0]

    @global_color_table_flag = (packed_field & GLOBAL_COLOR_TABLE_FLAG_MASK != 0)

    # iv) Color Resolution - Number of bits per primary color available
    # to the original image, minus 1. This value represents the size of
    # the entire palette from which the colors in the graphic were
    # selected, not the number of colors actually used in the graphic.
    # For example, if the value in this field is 3, then the palette of
    # the original image had 4 bits per primary color available to create
    # the image.  This value should be set to indicate the richness of
    # the original palette, even if not every color from the whole
    # palette is available on the source machine.
    @color_resolution = ((packed_field & COLOR_RESOLUTION_MASK) >> 4) + 1

    # v) Sort Flag - Indicates whether the Global Color Table is sorted.
    # If the flag is set, the Global Color Table is sorted, in order of
    # decreasing importance. Typically, the order would be decreasing
    # frequency, with most frequent color first. This assists a decoder,
    # with fewer available colors, in choosing the best subset of colors;
    # the decoder may use an initial segment of the table to render the
    # graphic.

    # Values :    0 -   Not ordered.
    #             1 -   Ordered by decreasing importance, most
    #                   important color first.
    @sort_flag = packed_field & SORT_FLAG_MASK != 0

    # vi) Size of Global Color Table - If the Global Color Table Flag is
    # set to 1, the value in this field is used to calculate the number
    # of bytes contained in the Global Color Table. To determine that
    # actual size of the color table, raise 2 to [the value of the field
    # + 1].  Even if there is no Global Color Table specified, set this
    # field according to the above formula so that decoders can choose
    # the best graphics mode to display the stream in.  (This field is
    # made up of the 3 least significant bits of the byte.)
    @size_of_global_color_table = 3 * (@color_resolution ** ((packed_field & SIZE_OF_GLOBAL_COLOR_TABLE_MASK) + 1))

    @background_color_index = bytes[11].unpack('C')[0]
    @pixel_aspect_ratio = bytes[12].unpack('C')[0]

    if @global_color_table_flag
      @global_color_table = []

      color_table = stream.read(@size_of_global_color_table)

      color_table.unpack('C*').each_slice(3) do |r, g, b|
        @global_color_table << [r, g, b]
      end
    end
  end
end
