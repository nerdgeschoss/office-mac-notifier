require "bundler/setup"
Bundler.require

class FritzBox
  attr_reader :sid
  attr_reader :base_url

  def initialize(host: "fritz.box", password:)
    @password = password
    @base_url = "http://#{host}/"
  end

  def login
    challenge = get("login_sid.lua").at_css("Challenge").text
    hash = Digest::MD5.hexdigest Iconv.conv("ucs-2le", "utf-8", "#{challenge}-#{@password}")
    sid = get("login_sid.lua?username=&response=#{challenge}-#{hash}").at_css("SID").text
    raise "Login failed" if sid.blank?
    @sid = sid
  end

  def logged_in?
    sid.present?
  end

  def devices
    raise "Not logged in" unless logged_in?
    data("netDev")["active"].map { |e| Device.parse(e) }
  end

  private

  def get(path)
    result = HTTParty.get(base_url + path).body
    Nokogiri::XML(result)
  end

  def post(path, params: {})
    body = params.map { |k, v| [k, v].compact.join("=") }.join("&")
    headers = { "Content-Type" => "application/x-www-form-urlencoded" }
    result = HTTParty.post(base_url + path, body: body, headers: headers).body
    JSON.parse result
  end

  def data(page)
    post("data.lua", params: { page: page, sid: sid, lang: :en, xhr: 1, xhrId: :cleanup, no_sidrenew: nil })["data"]
  end

  class Device
    include ActiveModel::Model

    attr_accessor :mac, :state, :ip, :name

    class << self
      def parse(e)
        new(name: e["name"], ip: e["ipv4"], mac: e["mac"], state: e["state"])
      end
    end
  end
end
