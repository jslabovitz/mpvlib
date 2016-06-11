require 'pp'
require 'ffi'
require 'mpv/ffi_additions'

# See <libmpv/client.h>.

module MPV

  extend FFI::Library

  ffi_lib 'libmpv'

end

require 'mpv/version'
require 'mpv/data'
require 'mpv/error'
require 'mpv/event'
require 'mpv/base'
require 'mpv/handle'