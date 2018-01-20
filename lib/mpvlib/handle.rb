module MPV

  typedef :pointer, :mpv_handle

  attach_function :mpv_create, [], :mpv_handle
  attach_function :mpv_initialize, [:mpv_handle], :int
  attach_function :mpv_detach_destroy, [:mpv_handle], :void
  attach_function :mpv_terminate_destroy, [:mpv_handle], :void

  attach_function :mpv_client_name, [:mpv_handle], :string

  # mpv_handle *mpv_create_client(mpv_handle *ctx, const char *name);

  # int mpv_load_config_file(mpv_handle *ctx, const char *filename);

  # void mpv_suspend(mpv_handle *ctx);
  # void mpv_resume(mpv_handle *ctx);

  attach_function :mpv_get_time_us, [:mpv_handle], :int64

  # int mpv_set_option(mpv_handle *ctx, const char *name, mpv_format format, void *data);
  attach_function :mpv_set_option_string, [:mpv_handle, :string, :string], :int

  attach_function :mpv_command, [:mpv_handle, :pointer], :int

  # int mpv_command_node(mpv_handle *ctx, mpv_node *args, mpv_node *result);
  # int mpv_command_string(mpv_handle *ctx, const char *args);

  attach_function :mpv_command_async, [:mpv_handle, :uint64, :pointer], :int
  # int mpv_command_node_async(mpv_handle *ctx, uint64_t reply_userdata, mpv_node *args);

  # attach_function :mpv_set_property, [:mpv_handle, :string, :mpv_format, :void], :int
  attach_function :mpv_set_property_string, [:mpv_handle, :string, :string], :int
  # int mpv_set_property_async(mpv_handle *ctx, uint64_t reply_userdata, const char *name, mpv_format format, void *data);

  # int mpv_get_property(mpv_handle *ctx, const char *name, mpv_format format, void *data);
  attach_function :mpv_get_property_string, [:mpv_handle, :string], :string
  # char *mpv_get_property_osd_string(mpv_handle *ctx, const char *name);
  # int mpv_get_property_async(mpv_handle *ctx, uint64_t reply_userdata, const char *name, mpv_format format);

  attach_function :mpv_observe_property, [:mpv_handle, :uint64, :string, :mpv_format], :int
  # int mpv_unobserve_property(mpv_handle *mpv, uint64_t registered_reply_userdata);

  # int mpv_request_event(mpv_handle *ctx, mpv_event_id event, int enable);

  attach_function :mpv_request_log_messages, [:mpv_handle, :string], :int

  attach_function :mpv_wait_event, [:mpv_handle, :double], MPVEvent.by_ref

  # void mpv_wakeup(mpv_handle *ctx);

  # void mpv_set_wakeup_callback(mpv_handle *ctx, void (*cb)(void *d), void *d);

  attach_function :mpv_get_wakeup_pipe, [:mpv_handle], :int

  # void mpv_wait_async_requests(mpv_handle *ctx);

  # typedef enum mpv_sub_api
  # void *mpv_get_sub_api(mpv_handle *ctx, mpv_sub_api sub_api);

  class Handle < Base

    attr_accessor :playlist_file
    attr_accessor :audio_device
    attr_accessor :mpv_log_level
    attr_accessor :equalizer
    attr_accessor :delegate
    attr_reader   :wakeup_pipe

    def initialize(
      playlist_file: nil,
      audio_device: nil,
      mpv_log_level: nil,
      equalizer: nil,
      delegate: nil,
      **params
    )
      @playlist_file = Path.new(playlist_file || '/tmp/playlist.txt')
      @audio_device = audio_device
      @mpv_log_level = mpv_log_level || 'error'
      @equalizer = equalizer
      @delegate = delegate
      @property_observers = {}
      @event_observers = {}
      @reply_id = 1
      @mpv_handle = MPV.mpv_create
      MPV::Error.raise_on_failure("initialize") {
        MPV.mpv_initialize(@mpv_handle)
      }
      define_finalizer(:mpv_terminate_destroy, @mpv_handle)
      fd = MPV.mpv_get_wakeup_pipe(@mpv_handle)
      raise StandardError, "Couldn't get wakeup pipe from MPV" if fd < 0
      @wakeup_pipe = IO.new(fd)
      register_event('log-message') { |e| handle_log_message(e) }
      request_log_messages(@mpv_log_level)
      set_option('audio-device', @audio_device) if @audio_device
      command('af', 'add', "equalizer=#{@equalizer.join(':')}") if @equalizer
      set_option('audio-display', 'no')
      set_option('vo', 'null')
      set_property('volume', '100')
      observe_property('playlist') { |e| @delegate.playlist_changed(e) } if @delegate
      observe_property('pause') { |e| @delegate.pause_changed(e) } if @delegate
      register_event('playback-restart') { |e| @delegate.playback_restart(e) } if @delegate
    end

    def client_name
      MPV.mpv_client_name(@mpv_handle)
    end

    def get_time_us
      MPV.mpv_get_time_us(@mpv_handle)
    end

    def set_option(name, value)
      #FIXME: allow non-string values
      MPV.mpv_set_option_string(@mpv_handle, name, value.to_s)
    end

    def command(*args)
      MPV::Error.raise_on_failure("command: args = %p" % args) {
        MPV.mpv_command(@mpv_handle, FFI::MemoryPointer.from_array_of_strings(args.map(&:to_s)))
      }
    end

    def command_async(*args, &block)
      @reply_id += 1
      MPV::Error.raise_on_failure("command_async: args = %p" % args) {
        MPV.mpv_command_async(@mpv_handle, @reply_id, FFI::MemoryPointer.from_array_of_strings(args.map(&:to_s)))
      }
      @property_observers[@reply_id] = block
      @reply_id
    end

    def set_property(name, data)
      #FIXME: allow non-string values
      MPV::Error.raise_on_failure("set_property: name = %p, data = %p" % [name, data]) {
        MPV.mpv_set_property_string(@mpv_handle, name, data.to_s)
      }
    end

    def get_property(name)
      #FIXME: allow non-string values
      MPV.mpv_get_property_string(@mpv_handle, name)
    end

    def observe_property(name, &block)
      @reply_id += 1
      MPV::Error.raise_on_failure("set_property: name = %p" % name) {
        MPV.mpv_observe_property(@mpv_handle, @reply_id, name, :MPV_FORMAT_STRING)
      }
      @property_observers[@reply_id] = block
      @reply_id
    end

    def register_event(name, &block)
      event_id = MPVEventNames[name] or raise "No such event: #{name.inspect}"
      @event_observers[event_id] ||= []
      @event_observers[event_id] << block
    end

    def wait_event(timeout: nil)
      Event.new_from_mpv_event(MPV.mpv_wait_event(@mpv_handle, timeout || -1))
    end

    def event_loop(timeout: nil)
      loop do
        event = wait_event(timeout: timeout)
        break if event.kind_of?(MPV::Event::None)
        raise event.error if event.error
        if event.reply_id && event.reply_id != 0 && (observer = @property_observers[event.reply_id])
          observer.call(event)
        end
        if (observers = @event_observers[event.event_id])
          observers.each { |o| o.call(event) }
        end
      end
    end

    def run_event_loop
      @wakeup_pipe.read_nonblock(1024)
      event_loop(timeout: 0)
    end

    def request_log_messages(level, &block)
      MPV::Error.raise_on_failure("request_log_messages: level = %p" % level) {
        MPV.mpv_request_log_messages(@mpv_handle, level)
      }
      register_event('log-message', &block) if block_given?
    end

    def playlist_position
      (v = get_property('playlist-pos')) && v.to_i
    end

    def playlist_position=(position)
      set_property('playlist-pos', position)
    end

    def playlist_count
      (v = get_property('playlist/count')) && v.to_i
    end

    def time_position
      (v = get_property('time-pos')) && v.to_f
    end

    def time_position=(position)
      set_property('time-pos', position)
    end

    def loadlist(path)
      command('loadlist', path.to_s)
    end

    def playlist_previous
      command('playlist-prev')
    end

    def playlist_next
      command('playlist-next')
    end

    def pause
      case get_property('pause')
      when 'no', nil
        false
      when 'yes'
        true
      end
    end

    def pause=(state)
      set_property('pause', state ? 'yes' : 'no')
    end

    def seek_by(seconds)
      command('seek', seconds)
    end

    def seek_to_percent(percent)
      command('seek', percent, 'absolute-percent')
    end

    def playlist_filename(position)
      if (filename = get_property("playlist/#{position}/filename")) && !filename.empty?
        Path.new(filename)
      else
        nil
      end
    end

    def playlist
      JSON.parse(get_property('playlist')).map { |h| HashStruct.new(h) }
    end

    def play(playlist=nil)
      if playlist
        @playlist_file.dirname.mkpath
        @playlist_file.open('w') do |io|
          playlist.each { |p|
            raise "Track in playlist not defined or nonexistant: #{p.inspect}" unless p && p.exist?
            io.puts(p)
          }
        end
      end
      loadlist(@playlist_file)
    end

    MPVLogMessageLevels = {
      'none'  => Logger::UNKNOWN,
      'fatal' => Logger::FATAL,
      'error' => Logger::ERROR,
      'warn'  => Logger::WARN,
      'info'  => Logger::INFO,
      'v'     => Logger::DEBUG,
      'debug' => Logger::DEBUG,
      'trace' => Logger::DEBUG,
    }

    def handle_log_message(log_message)
      if @delegate
        @delegate.add_log_message(
          MPVLogMessageLevels[log_message.level] || Logger::UNKNOWN,
          '%15s: %s' % [log_message.prefix, log_message.text.chomp],
          'MPV')
      end
    end

  end

end