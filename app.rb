require 'sinatra'
require 'sinatra/cross_origin'
require 'json'

class Regexer
  def scan_string(str, reg, opt)
    begin
      o = reorder_options opt
      regex = create_regex reg, o
    rescue StandardError, RuntimeError, RegexpError => e
      return error_handle e.message
    else 
      res = str.scan(regex)
      return converter res
    end
  end

  def is_invalid?(reg)
    counter = 0

    while counter < reg.length
      if reg[counter] === '/' && (reg[counter - 1].nil? || reg[counter - 1] != "\\")
        return true
      end

      counter += 1
    end

    false
  end

  def error_handle(msg)
    return { 'ERROR_915_JM_111' => msg }.to_json
  end

  private

  def create_regex(reg, opt) 
    o = {
      '' => 0,
      'i' => Regexp::IGNORECASE,
      'm' => Regexp::MULTILINE,
      'x' => Regexp::EXTENDED,
      'im' => Regexp::IGNORECASE | Regexp::MULTILINE,
      'mx' => Regexp::MULTILINE | Regexp::EXTENDED,
      'ix' => Regexp::IGNORECASE | Regexp::EXTENDED,
      'imx' => Regexp::IGNORECASE | Regexp::MULTILINE | Regexp::EXTENDED
    }

    return Regexp.new(reg, o[opt])
  end

  def reorder_options(opt) 
    str = ''

    if opt.include? 'i'
      str += 'i'
    end

    if opt.include? 'm'
      str += 'm'
    end

    if opt.include? 'x'
      str += 'x'
    end

    str
  end

  def converter(matches)
    ret = {}

    matches.each do |x|
      if ret[x] == nil
        ret[x] = 0
      end

      ret[x] += 1
    end

    ret.to_json   
  end
end

set :bind, '0.0.0.0'

configure do
  enable :cross_origin
end

before do
  response.headers['Access-Control-Allow-Methods'] = 'GET, POST, PUT, DELETE, OPTIONS'
  response.headers['Access-Control-Allow-Origin'] = '*'
  response.headers['Access-Control-Allow-Headers'] = 'accept, authorization, origin'
  request.body.rewind
  @request_payload = JSON.parse request.body.read
end

post "/test" do 
  regex = @request_payload['regex']
  string = @request_payload['string']
  option = @request_payload['opt']

  tester = Regexer.new

  return tester.error_handle 'forward slashes must be escaped.' if tester.is_invalid? regex
  return tester.scan_string(string, regex, option)
end

options "*" do
  response.headers["Allow"] = "GET, PUT, POST, DELETE, OPTIONS"
  response.headers["Access-Control-Allow-Headers"] = "Authorization, Content-Type, Accept, X-User-Email, X-Auth-Token"
  response.headers["Access-Control-Allow-Origin"] = "*"
  response.status = 200
end