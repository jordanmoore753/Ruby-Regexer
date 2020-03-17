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

  def test_regexer_says_invalid
    res = Regexer.new

    assert_equal res.is_invalid?('/invalid/'), true
    assert_equal res.is_invalid?('invalid'), false
    assert_equal res.is_invalid?('//invalid/'), true
    assert_equal res.is_invalid?('\/invalid'), false
    assert_equal res.is_invalid?('inv/alid'), true
    assert_equal res.is_invalid?('inv\/alid'), false
  end

  def test_regexer_handles_error
    res = Regexer.new

    assert_equal res.error_handle('Invalid.'), { 'ERROR_915_JM_111' => 'Invalid.' }.to_json
    assert_equal res.error_handle('target of repeat operator is not specified: /+/'), { 'ERROR_915_JM_111' => 'target of repeat operator is not specified: /+/' }.to_json
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
    try = { 'string' => ["blueberry\nblackberry\nblack berry"], 'regex' => '(blue|black)berry', 'opt' => 'i' }.to_json
    post '/test', try, { 'CONTENT-TYPE' => 'application/json'}
    body = JSON.parse last_response.body

    assert_equal body['match'], ["<p><span class=\"highlight\">blueberry</span>\n<span class=\"highlight\">blackberry</span>\nblack berry</p>"]
    assert_equal body['groups'], {"[\"blue\"]"=>1, "[\"black\"]"=>1} 

    try = { 'string' => ["one more to go"], 'regex' => '\w+', 'opt' => '' }.to_json
    post '/test', try, { 'CONTENT-TYPE' => 'application/json'}
    body = JSON.parse last_response.body

    assert_equal body['match'], ["<p><span class=\"highlight\">one</span> <span class=\"highlight\">more</span> <span class=\"highlight\">to</span> <span class=\"highlight\">go</span></p>"]
    assert_equal body['groups'], {}

    try = { 'string' => ['Hello 4567 bye CDEF - cdef'], 'regex' => '\s\h\h\h\h\s', 'opt' => '' }.to_json
    post '/test', try, { 'CONTENT-TYPE' => 'application/json'}
    body = JSON.parse last_response.body

    assert_equal body['match'], ["<p>Hello<span class=\"highlight\"> 4567 </span>bye<span class=\"highlight\"> CDEF </span>- cdef</p>"]
    assert_equal body['groups'], {}

    try = { 'string' => ['the lazy cat sleeps'], 'regex' => '\s...\s', 'opt' => '' }.to_json
    post '/test', try, { 'CONTENT-TYPE' => 'application/json'}
    body = JSON.parse last_response.body

    assert_equal body['match'], ['<p>the lazy<span class="highlight"> cat </span>sleeps</p>']
    assert_equal body['groups'], {}

    try = { 'string' => ["Kitchen Kaboodle\nReds and blues\nkitchen Servers"], 'regex' => '[Kks]', 'opt' => '' }.to_json
    post '/test', try, { 'CONTENT-TYPE' => 'application/json'}
    body = JSON.parse last_response.body

    assert_equal body['match'], ["<p><span class=\"highlight\">K</span>itchen <span class=\"highlight\">K</span>aboodle\nRed<span class=\"highlight\">s</span> and blue<span class=\"highlight\">s</span>\n<span class=\"highlight\">k</span>itchen Server<span class=\"highlight\">s</span></p>"]
    assert_equal body['groups'], {}

    try = { 'string' => ['0x1234abcd'], 'regex' => "[^a-z]", 'opt' => 'i' }.to_json
    post '/test', try, { 'CONTENT-TYPE' => 'application/json'}
    body = JSON.parse last_response.body

    assert_equal body['match'], ['<p><span class="highlight">0</span>x<span class="highlight">1</span><span class="highlight">2</span><span class="highlight">3</span><span class="highlight">4</span>abcd</p>']
    assert_equal body['groups'], {}

    try = { 'string' => ["The regex /[^a-z]/i matches"], 'regex' => '\[\^[0-9A-Za-z]-[0-9A-Za-z]\]', 'opt' => '' }.to_json
    post '/test', try, { 'CONTENT-TYPE' => 'application/json'}
    body = JSON.parse last_response.body

    assert_equal body['match'], ['<p>The regex /<span class="highlight">[^a-z]</span>/i matches</p>']
    assert_equal body['groups'], {}

    try = { 'string' => ["The lazy cat sleeps", "The number 623 is not a cat", "The Alaskan drives a snowcat"], 'regex' => '\bcat$', 'opt' => '' }.to_json
    post '/test', try, { 'CONTENT-TYPE' => 'application/json'}
    body = JSON.parse last_response.body

    assert_equal body['match'], ["<p>The lazy cat sleeps</p>", "<p>The number 623 is not a <span class=\"highlight\">cat</span></p>", "<p>The Alaskan drives a snowcat</p>"]
    assert_equal body['groups'], {}

    try = { 'string' => ["A loud dog"], 'regex' => '^(A|The) [a-zA-Z][a-zA-Z][a-zA-Z][a-zA-Z] (dog|cat)$', 'opt' => '' }.to_json
    post '/test', try, { 'CONTENT-TYPE' => 'application/json'}
    body = JSON.parse last_response.body

    assert_equal body['match'], ['<p><span class="highlight">A loud dog</span></p>']
    assert_equal body['groups'], {"[\"A\", \"dog\"]"=>1}

    try = { 'string' => ["To be or not to be"], 'regex' => '\bb[a-z]*e\b', 'opt' => '' }.to_json
    post '/test', try, { 'CONTENT-TYPE' => 'application/json'}
    body = JSON.parse last_response.body

    assert_equal body['match'], ['<p>To <span class="highlight">be</span> or not to <span class="highlight">be</span></p>']
    assert_equal body['groups'], {}   

    try = { 'string' => ["What's up, doc?"], 'regex' => '^.*\?$', 'opt' => '' }.to_json
    post '/test', try, { 'CONTENT-TYPE' => 'application/json'}
    body = JSON.parse last_response.body

    assert_equal body['match'], ['<p><span class="highlight">What\'s up, doc?</span></p>']
    assert_equal body['groups'], {}

    try = { 'string' => ["Mississippi", "Atlanta"], 'regex' => '\b[a-z]*i[a-z]*i[a-z]*i[a-z]*\b', 'opt' => 'i' }.to_json
    post '/test', try, { 'CONTENT-TYPE' => 'application/json'}
    body = JSON.parse last_response.body

    assert_equal body['match'], ["<p><span class=\"highlight\">Mississippi</span></p>", "<p>Atlanta</p>"]
    assert_equal body['groups'], {}

    try = { 'string' => ["String to match.", "", "String!"], 'regex' => 'String', 'opt' => '' }.to_json
    post '/test', try, { 'CONTENT-TYPE' => 'application/json'}
    body = JSON.parse last_response.body

    assert_equal body['match'], ["<p><span class=\"highlight\">String</span> to match.</p>", "<br>", "<p><span class=\"highlight\">String</span>!</p>"]
    assert_equal body['groups'], {}
  end
end