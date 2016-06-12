require 'test_helper'

module MPV

  class HandleTest < Minitest::Test

    def setup
      @mpv = MPV::Handle.new
    end

    def test_client_name
      assert { @mpv.client_name == 'main' }
    end

    def test_time_us
      assert { @mpv.get_time_us.kind_of?(Numeric) }
    end

    def test_good_command
      assert {
        @mpv.command('stop')
        true
      }
    end

    def test_bad_command
      # FIXME: why doesn't this raise the right kind of error?
      # assert_raises(MPV::Error) {
      assert_raises(RuntimeError) {
        @mpv.command('xyzzy')
        true
      }
    end

    def test_get_property
      assert { @mpv.get_property('volume').to_f == 100.0 }
    end

    def test_set_property
      name, data = 'volume', 50.0
      @mpv.set_property(name, data)
      assert { @mpv.get_property(name).to_f == data }
    end

    def test_observe_property
      expected_property, expected_value = 'volume', 50.0
      @mpv.set_property(expected_property, expected_value.to_s)
      actual_property = actual_value = nil
      @mpv.observe_property(expected_property) do |property|
        actual_property = property.name
        actual_value = property.value
        raise MPV::StopEventLoop
      end
      @mpv.each_event(timeout: 0.1) do |event|
        # ignore
      end
      assert { actual_property == expected_property }
      assert { actual_value.to_s.to_f == expected_value }
    end

    def test_wakeup_pipe
      @mpv.request_log_messages('v')
      pipe = @mpv.get_wakeup_pipe
      state = 0
      loop do
        ready = IO.select([pipe], [], [], 1)
        if ready
          reads = ready.first
          if reads.include?(pipe)
            pipe.read_nonblock(1024)
            @mpv.each_event(timeout: 0) do |event|
              # ignore
            end
          end
        else
          case state
          when 0
            @mpv.command_async('stop')
            state += 1
          when 1
            break
          end
        end
      end
    end

  end

end