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
      assert_raises(MPV::Error) {
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
      stop = false
      @mpv.observe_property(expected_property) do |property|
        actual_property = property.name
        actual_value = property.value
        stop = true
      end
      until stop
        @mpv.event_loop(timeout: 0)
      end
      assert { actual_property == expected_property }
      assert { actual_value.to_s.to_f == expected_value }
    end

    def test_process_events
      stop = false
      @mpv.request_log_messages('v') do |event|
        stop = true if event.text =~ /Set property string/
      end
      @mpv.set_property('volume', 50.0)
      until stop
        if (IO.select([@mpv.get_wakeup_pipe], [], [], 1))
          @mpv.get_wakeup_pipe.read_nonblock(1024)
          @mpv.event_loop(timeout: 0)
        else
          raise 'timeout'
        end
      end
    end

  end

end