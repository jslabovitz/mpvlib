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
      @mpv.observe_property(expected_property) do |property, value|
        actual_property = property
        actual_value = value
      end
      loop do
        event = @mpv.wait_event(1)
        raise event.error if event.error
        case event
        when MPV::Event::None
          break
        when MPV::Event::PropertyChange
          actual_property = event.name
          actual_value = event.value
          break
        end
      end
      assert { actual_property == expected_property }
      assert { actual_value.to_s.to_f == expected_value }
    end

  end

end