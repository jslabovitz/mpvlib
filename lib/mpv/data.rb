module MPV

  enum :mpv_format, [
    :MPV_FORMAT_NONE,       0,
    :MPV_FORMAT_STRING,     1,
    :MPV_FORMAT_OSD_STRING, 2,
    :MPV_FORMAT_FLAG,       3,
    :MPV_FORMAT_INT64,      4,
    :MPV_FORMAT_DOUBLE,     5,
    :MPV_FORMAT_NODE,       6,
    :MPV_FORMAT_NODE_ARRAY, 7,
    :MPV_FORMAT_NODE_MAP,   8,
    :MPV_FORMAT_BYTE_ARRAY, 9,
  ]

  # typedef struct mpv_node
  # typedef struct mpv_node_list
  # typedef struct mpv_byte_array
  # void mpv_free_node_contents(mpv_node *node);

  attach_function :mpv_free, [:void], :void

  def self.convert_data(data, format)
    ptr = data.read_pointer
    case format
    when :MPV_FORMAT_NONE
      nil
    when :MPV_FORMAT_STRING, :MPV_FORMAT_OSD_STRING
      ptr.read_string
    else
      raise "Unknown format: #{format.inspect}"
    end
  end

end