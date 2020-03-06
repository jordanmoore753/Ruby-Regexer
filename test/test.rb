ENV['RACK_ENV'] = 'test'

require 'minitest/autorun'
require 'rack/test'
require 'json'
require_relative '../app'

class AppTest < Minitest::Test
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def test_regexer_exists
    res = Regexer.new
    assert res
  end

  def test_invalid_regex
    try = { 'string' => 'test', 'regex' => '+', 'opt' => '' }.to_json
    post '/test', try, { 'CONTENT-TYPE' => 'application/json'}
    body = JSON.parse last_response.body

    assert_equal body['ERROR_915_JM_111'], "target of repeat operator is not specified: /+/"

    try = { 'string' => 'test', 'regex' => '*', 'opt' => '' }.to_json
    post '/test', try, { 'CONTENT-TYPE' => 'application/json'}
    body = JSON.parse last_response.body

    assert_equal body['ERROR_915_JM_111'], "target of repeat operator is not specified: /*/"

    try = { 'string' => 'test', 'regex' => '{2}', 'opt' => ''  }.to_json
    post '/test', try, { 'CONTENT-TYPE' => 'application/json'}
    body = JSON.parse last_response.body

    assert_equal body['ERROR_915_JM_111'], "target of repeat operator is not specified: /{2}/"

    try = { 'string' => 'test', 'regex' => '/', 'opt' => '' }.to_json
    post '/test', try, { 'CONTENT-TYPE' => 'application/json'}
    body = JSON.parse last_response.body

    assert_equal body['ERROR_915_JM_111'], "forward slashes must be escaped."

    try = { 'string' => 'test', 'regex' => '[]', 'opt' => '' }.to_json
    post '/test', try, { 'CONTENT-TYPE' => 'application/json'}
    body = JSON.parse last_response.body

    assert_equal body['ERROR_915_JM_111'], "empty char-class: /[]/"
  end

  def test_valid_regex
    try = { 'string' => 'one more to go', 'regex' => '\w+', 'opt' => '' }.to_json
    post '/test', try, { 'CONTENT-TYPE' => 'application/json'}
    body = JSON.parse last_response.body

    assert_equal body, {"one"=>1, "more"=>1, "to"=>1, "go"=>1}
  end
end