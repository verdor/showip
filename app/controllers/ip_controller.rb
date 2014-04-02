class IpController < ApplicationController
  layout false

  def index
    @client_ip = remote_ip()
  end
end
