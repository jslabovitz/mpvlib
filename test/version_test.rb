require 'test_helper'

module MPV

  class VersionTest < Minitest::Test

    MinimumAPIVersion = [1, 20]

    def test_api_version
      version = MPV.client_api_version
      minimum_api_version = MPV.make_version(*MinimumAPIVersion)
      assert { version >= minimum_api_version }
    end

    def test_api_version_elements
      major, minor = MPV.client_api_version_elements
      assert { major.kind_of?(Numeric) }
      assert { minor.kind_of?(Numeric) }
    end

  end

end