module MPV

  attach_function :mpv_client_api_version, [], :uint32

  def self.client_api_version
    MPV.mpv_client_api_version
  end

  def self.make_version(major, minor)
    (major << 16) | minor
  end

  def self.client_api_version_elements
    long = MPV.mpv_client_api_version
    [long >> 16, long & 0x00FF]
  end

end