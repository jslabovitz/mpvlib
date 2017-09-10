module MPV

  enum :mpv_error, [
    :MPV_ERROR_SUCCESS,                 0,
    :MPV_ERROR_EVENT_QUEUE_FULL,       -1,
    :MPV_ERROR_NOMEM,                  -2,
    :MPV_ERROR_UNINITIALIZED,          -3,
    :MPV_ERROR_INVALID_PARAMETER,      -4,
    :MPV_ERROR_OPTION_NOT_FOUND,       -5,
    :MPV_ERROR_OPTION_FORMAT,          -6,
    :MPV_ERROR_OPTION_ERROR,           -7,
    :MPV_ERROR_PROPERTY_NOT_FOUND,     -8,
    :MPV_ERROR_PROPERTY_FORMAT,        -9,
    :MPV_ERROR_PROPERTY_UNAVAILABLE,  -10,
    :MPV_ERROR_PROPERTY_ERROR,        -11,
    :MPV_ERROR_COMMAND,               -12,
    :MPV_ERROR_LOADING_FAILED,        -13,
    :MPV_ERROR_AO_INIT_FAILED,        -14,
    :MPV_ERROR_VO_INIT_FAILED,        -15,
    :MPV_ERROR_NOTHING_TO_PLAY,       -16,
    :MPV_ERROR_UNKNOWN_FORMAT,        -17,
    :MPV_ERROR_UNSUPPORTED,           -18,
    :MPV_ERROR_NOT_IMPLEMENTED,       -19,
  ]

  attach_function :mpv_error_string, [:int], :string

  class Error < StandardError

    def self.raise_on_failure(msg=nil, &block)
      error = yield
      raise new(error, msg) if error && error < 0
    end

    def self.error_to_string(error)
      MPV.mpv_error_string(error)
    end

    def initialize(error, msg=nil)
      super('MPV error: %s (%s): %s' %
        [
          self.class.error_to_string(error),
          error,
          msg,
        ]
      )
    end

  end

end