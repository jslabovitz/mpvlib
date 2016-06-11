require 'test_helper'

module MPV

  class ErrorTest < Minitest::Test

    def test_error_string
      assert { MPV::Error.error_to_string(:MPV_ERROR_SUCCESS) == 'success' }
    end

    def test_error_exception
      error = MPV::Error.new(:MPV_ERROR_SUCCESS)
      assert { error.kind_of?(MPV::Error) }
    end

  end

end