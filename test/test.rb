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

    try = { 'string' => 'Hello 4567 bye CDEF - cdef', 'regex' => '\s\h\h\h\h\s', 'opt' => '' }.to_json
    post '/test', try, { 'CONTENT-TYPE' => 'application/json'}
    body = JSON.parse last_response.body

    assert_equal body, {" 4567 "=>1, " CDEF "=>1}

    try = { 'string' => 'the lazy cat sleeps', 'regex' => '\s...\s', 'opt' => '' }.to_json
    post '/test', try, { 'CONTENT-TYPE' => 'application/json'}
    body = JSON.parse last_response.body

    assert_equal body, {" cat "=>1}

    try = { 'string' => "Kitchen Kaboodle\nReds and blues\nkitchen Servers", 'regex' => '[Kks]', 'opt' => '' }.to_json
    post '/test', try, { 'CONTENT-TYPE' => 'application/json'}
    body = JSON.parse last_response.body

    assert_equal body, {"K"=>2, "s"=>3, "k"=>1}

    try = { 'string' => "Kitchen Kaboodle\nReds and blues\nkitchen Servers", 'regex' => '[Kks]', 'opt' => 'i' }.to_json
    post '/test', try, { 'CONTENT-TYPE' => 'application/json'}
    body = JSON.parse last_response.body

    assert_equal body, {"K"=>2, "s"=>3, "k"=>1, "S"=>1}

    try = { 'string' => '0x1234abcd', 'regex' => "[^a-z]", 'opt' => 'i' }.to_json
    post '/test', try, { 'CONTENT-TYPE' => 'application/json'}
    body = JSON.parse last_response.body

    assert_equal body, {"0"=>1, "1"=>1, "2"=>1, "3"=>1, "4"=>1}

    try = { 'string' => "The regex /[^a-z]/i matches", 'regex' => '\[\^[0-9A-Za-z]-[0-9A-Za-z]\]', 'opt' => '' }.to_json
    post '/test', try, { 'CONTENT-TYPE' => 'application/json'}
    body = JSON.parse last_response.body

    assert_equal body, {"[^a-z]"=>1}

    try = { 'string' => "The lazy cat sleeps\nThe number 623 is not a cat\nThe Alaskan drives a snowcat", 'regex' => '\bcat$', 'opt' => '' }.to_json
    post '/test', try, { 'CONTENT-TYPE' => 'application/json'}
    body = JSON.parse last_response.body

    assert_equal body, {"cat"=>1}

    try = { 'string' => "A loud dog", 'regex' => '^(A|The) [a-zA-Z][a-zA-Z][a-zA-Z][a-zA-Z] (dog|cat)$', 'opt' => '' }.to_json
    post '/test', try, { 'CONTENT-TYPE' => 'application/json'}
    body = JSON.parse last_response.body

    assert_equal body, {"[\"A\", \"dog\"]"=>1}

    try = { 'string' => "To be or not to be", 'regex' => '\bb[a-z]*e\b', 'opt' => '' }.to_json
    post '/test', try, { 'CONTENT-TYPE' => 'application/json'}
    body = JSON.parse last_response.body

    assert_equal body, {"be"=> 2}   

    try = { 'string' => "What's up, doc?", 'regex' => '^.*\?$', 'opt' => '' }.to_json
    post '/test', try, { 'CONTENT-TYPE' => 'application/json'}
    body = JSON.parse last_response.body

    assert_equal body, {"What's up, doc?"=> 1}

    try = { 'string' => "Mississippi", 'regex' => '\b[a-z]*i[a-z]*i[a-z]*i[a-z]*\b', 'opt' => 'i' }.to_json
    post '/test', try, { 'CONTENT-TYPE' => 'application/json'}
    body = JSON.parse last_response.body

    assert_equal body, {"Mississippi"=> 1}  
  end
end