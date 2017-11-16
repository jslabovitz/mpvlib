require 'pp'
require 'path'
require 'json'
require 'hashstruct'
require 'logger'
require 'ffi'
require 'mpvlib/ffi_additions'

# See <libmpv/client.h>.

module MPV

  extend FFI::Library

  ffi_lib 'libmpv'

end

require 'mpvlib/version'
require 'mpvlib/data'
require 'mpvlib/error'
require 'mpvlib/event'
require 'mpvlib/base'
require 'mpvlib/handle'