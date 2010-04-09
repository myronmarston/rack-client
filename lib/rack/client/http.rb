require 'net/https'

class Rack::Client::HTTP
  def self.call(env)
    new(env).run
  end

  def initialize(env)
    @env = env
  end

  def run
    request_klass = case request.request_method
    when "HEAD"
      Net::HTTP::Head
    when "GET"
      Net::HTTP::Get
    when "POST"
      Net::HTTP::Post
    when "PUT"
      Net::HTTP::Put
    when "DELETE"
      Net::HTTP::Delete
    else
      raise "Unsupported method: #{request.request_method.inspect}"
    end

    request_object = request_klass.new(request.path, request_headers)

    if %w( POST PUT ).include?(request.request_method)
      request_object.body = @env["rack.input"].read
    end

    parse(http.request(request_object))
  end

  def https?
    request.scheme == 'https'
  end

  def http
    http = Net::HTTP.new(request.host, request.port)
    if https?
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    end
    http
  end

  def parse(response)
    status = response.code.to_i
    headers = {}
    response.each do |key,value|
      key = key.gsub(/(\w+)/) do |matches|
        matches.sub(/^./) do |char|
          char.upcase
        end
      end
      headers[key] = value
    end
    [status, headers, response.body.to_s]
  end

  def request
    @request ||= Rack::Request.new(@env)
  end

  def request_headers
    headers = {}
    @env.each do |k,v|
      if k =~ /^HTTP_(.*)$/
        headers[$1] = v
      end
    end
    headers
  end
end
