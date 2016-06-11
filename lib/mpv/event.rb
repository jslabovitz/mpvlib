module MPV

  enum :mpv_event_id, [
    :MPV_EVENT_NONE,                  0,
    :MPV_EVENT_SHUTDOWN,              1,
    :MPV_EVENT_LOG_MESSAGE,           2,
    :MPV_EVENT_GET_PROPERTY_REPLY,    3,
    :MPV_EVENT_SET_PROPERTY_REPLY,    4,
    :MPV_EVENT_COMMAND_REPLY,         5,
    :MPV_EVENT_START_FILE,            6,
    :MPV_EVENT_END_FILE,              7,
    :MPV_EVENT_FILE_LOADED,           8,
    :MPV_EVENT_TRACKS_CHANGED,        9,
    :MPV_EVENT_TRACK_SWITCHED,        10,
    :MPV_EVENT_IDLE,                  11,
    :MPV_EVENT_PAUSE,                 12,
    :MPV_EVENT_UNPAUSE,               13,
    :MPV_EVENT_TICK,                  14,
    :MPV_EVENT_SCRIPT_INPUT_DISPATCH, 15,
    :MPV_EVENT_CLIENT_MESSAGE,        16,
    :MPV_EVENT_VIDEO_RECONFIG,        17,
    :MPV_EVENT_AUDIO_RECONFIG,        18,
    :MPV_EVENT_METADATA_UPDATE,       19,
    :MPV_EVENT_SEEK,                  20,
    :MPV_EVENT_PLAYBACK_RESTART,      21,
    :MPV_EVENT_PROPERTY_CHANGE,       22,
    :MPV_EVENT_CHAPTER_CHANGE,        23,
    :MPV_EVENT_QUEUE_OVERFLOW,        24,
  ]

  attach_function :mpv_event_name, [:mpv_event_id], :string

  class MPVEventProperty < FFI::Struct

    layout \
      :name,    :string,
      :format,  :mpv_format,
      :data,    :pointer

  end

  enum :mpv_log_level, [
    :MPV_LOG_LEVEL_NONE,  0,
    :MPV_LOG_LEVEL_FATAL, 10,
    :MPV_LOG_LEVEL_ERROR, 20,
    :MPV_LOG_LEVEL_WARN,  30,
    :MPV_LOG_LEVEL_INFO,  40,
    :MPV_LOG_LEVEL_V,     50,
    :MPV_LOG_LEVEL_DEBUG, 60,
    :MPV_LOG_LEVEL_TRACE, 70,
  ]

  class MPVEventLogMessage < FFI::Struct

    layout \
      :prefix,    :string,
      :level,     :string,
      :text,      :string,
      :log_level, :mpv_log_level

  end

  enum :mpv_end_file_reason, [
    :MPV_END_FILE_REASON_EOF,       0,
    :MPV_END_FILE_REASON_STOP,      2,
    :MPV_END_FILE_REASON_QUIT,      3,
    :MPV_END_FILE_REASON_ERROR,     4,
    :MPV_END_FILE_REASON_REDIRECT,  5,
  ]

  class MPVEventEndFile < FFI::Struct

    layout \
      :reason, :int,
      :error,  :int

  end

  # typedef struct mpv_event_script_input_dispatch -- DEPRECATED

  class MPVEventClientMessage < FFI::Struct

    layout \
      :num_args,  :int,
      :args,      :pointer

  end

  class MPVEvent < FFI::Struct

    layout \
      :event_id,        :mpv_event_id,
      :error,           :int,
      :reply_userdata,  :uint64,
      :data,            :pointer

  end

  class Event

    class None < Event; end

    class Shutdown < Event; end

    class LogMessage < Event

      attr_accessor :prefix
      attr_accessor :level
      attr_accessor :text
      attr_accessor :log_level

      def initialize(mpv_event)
        super
        data = MPVEventLogMessage.new(mpv_event[:data])
        @prefix = data[:prefix]
        @level = data[:level]
        @text = data[:text]
        @log_level = data[:log_level]
      end

    end

    class GetPropertyReply < Event

      attr_accessor :name
      attr_accessor :value

      def initialize(mpv_event)
        super
        data = MPVEventProperty.new(mpv_event[:data])
        @name = data[:name]
        @value = MPV.convert_data(data[:data], data[:format])
      end

    end

    class SetProperty < Event; end

    class CommandReply < Event; end

    class StartFile < Event; end

    class EndFile < Event

      attr_accessor :reason
      attr_accessor :error

      def initialize(mpv_event)
        super
        data = MPVEventEndFile.new(mpv_event[:data])
        @reason = data[:reason]
        @error = (data[:error] < 0) ? MPV::Error.new(data[:error]) : nil
      end

    end

    class FileLoaded < Event; end

    class TracksChanged < Event; end

    class TrackSwitched < Event; end

    class Idle < Event; end

    class Pause < Event; end

    class Unpause < Event; end

    class Tick < Event; end

    class ScriptInputDispatch < Event; end

    class ClientMessage < Event

      attr_accessor :args

      def initialize(mpv_event)
        super
        data = MPVEventLogMessage.new(mpv_event[:data])
        @args = data[:args].read_array_of_strings(data[:num_args])
      end

    end

    class VideoReconfig < Event; end

    class AudioReconfig < Event; end

    class MetadataUpdate < Event; end

    class Seek < Event; end

    class PlaybackRestart < Event; end

    class PropertyChange < GetPropertyReply; end

    class ChapterChange < Event; end

    class QueueOverflow < Event; end

    def self.new_from_mpv_event(mpv_event)
      event_class_name = mpv_event[:event_id].to_s.sub(/^MPV_EVENT_/, '').split('_').map(&:capitalize).join
      event_class = const_get(event_class_name)
      event_class.new(mpv_event)
    end

    attr_accessor :error
    attr_accessor :reply_id

    def initialize(mpv_event)
      @error = (mpv_event[:error] < 0) ? MPV::Error.new(mpv_event[:error]) : nil
      @reply_id = mpv_event[:reply_userdata]
    end

  end

end