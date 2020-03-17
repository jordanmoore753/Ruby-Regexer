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
      newString = []
      
      str.each do |s|
        newString.push s.gsub(regex, '<span class="highlight">\0</span>')
      end

      res = []

      str.each do |s|
        res.push s.scan(regex)
      end

      res = get_capture_groups res
      return converter res, newString
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

  def get_capture_groups(m)
    res = {}

    m.each { |s| s.each { |x| res[x] = 1 } if s[0].is_a? Array }

    res
  end

  def converter(m, s)
    ret = {} 
    matches = []

    s.each do |str|
      a = '<p>'
      a += str + '</p>'
      matches.push a
    end

    ret['groups'] = m
    ret['match'] = matches
    ret.to_json   
  end
end

set :bind, '0.0.0.0'

configure do
  enable :cross_origin
end

before do
  response.headers['Access-Control-Allow-Origin'] = '*'
  200
end

post "/test" do 
  request.body.rewind
  @request_payload = JSON.parse request.body.read

  regex = @request_payload['regex']
  string = @request_payload['string']
  option = @request_payload['opt']

  tester = Regexer.new

  return tester.error_handle 'forward slashes must be escaped.' if tester.is_invalid? regex
  tester.scan_string(string, regex, option)
end

options "*" do
  response.headers["Allow"] = "GET, PUT, POST, DELETE, OPTIONS"
  response.headers["Access-Control-Allow-Headers"] = "Authorization, Content-Type, Accept, X-User-Email, X-Auth-Token"
  response.headers["Access-Control-Allow-Origin"] = "*"
  response.status = 200
end