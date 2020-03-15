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
    try = { 'string' => 'one more to go', 'regex' => '\w+', 'opt' => '' }.to_json
    post '/test', try, { 'CONTENT-TYPE' => 'application/json'}
    body = JSON.parse last_response.body

    assert_equal body['match'], '<span class="highlight">one</span> <span class="highlight">more</span> <span class="highlight">to</span> <span class="highlight">go</span>'
    assert_equal body['groups'], {"one"=>1, "more"=>1, "to"=>1, "go"=>1}

    try = { 'string' => 'Hello 4567 bye CDEF - cdef', 'regex' => '\s\h\h\h\h\s', 'opt' => '' }.to_json
    post '/test', try, { 'CONTENT-TYPE' => 'application/json'}
    body = JSON.parse last_response.body

    assert_equal body['match'], 'Hello<span class="highlight"> 4567 </span>bye<span class="highlight"> CDEF </span>- cdef'
    assert_equal body['groups'], {" 4567 "=>1, " CDEF "=>1}

    try = { 'string' => 'the lazy cat sleeps', 'regex' => '\s...\s', 'opt' => '' }.to_json
    post '/test', try, { 'CONTENT-TYPE' => 'application/json'}
    body = JSON.parse last_response.body

    assert_equal body['match'], 'the lazy<span class="highlight"> cat </span>sleeps'
    assert_equal body['groups'], {" cat "=>1}

    try = { 'string' => "Kitchen Kaboodle\nReds and blues\nkitchen Servers", 'regex' => '[Kks]', 'opt' => '' }.to_json
    post '/test', try, { 'CONTENT-TYPE' => 'application/json'}
    body = JSON.parse last_response.body

    assert_equal body['match'], "<span class=\"highlight\">K</span>itchen <span class=\"highlight\">K</span>aboodle\nRed<span class=\"highlight\">s</span> and blue<span class=\"highlight\">s</span>\n<span class=\"highlight\">k</span>itchen Server<span class=\"highlight\">s</span>"
    assert_equal body['groups'], {"K"=>2, "s"=>3, "k"=>1}

    try = { 'string' => '0x1234abcd', 'regex' => "[^a-z]", 'opt' => 'i' }.to_json
    post '/test', try, { 'CONTENT-TYPE' => 'application/json'}
    body = JSON.parse last_response.body

    assert_equal body['match'], '<span class="highlight">0</span>x<span class="highlight">1</span><span class="highlight">2</span><span class="highlight">3</span><span class="highlight">4</span>abcd'
    assert_equal body['groups'], {"0"=>1, "1"=>1, "2"=>1, "3"=>1, "4"=>1}

    try = { 'string' => "The regex /[^a-z]/i matches", 'regex' => '\[\^[0-9A-Za-z]-[0-9A-Za-z]\]', 'opt' => '' }.to_json
    post '/test', try, { 'CONTENT-TYPE' => 'application/json'}
    body = JSON.parse last_response.body

    assert_equal body['match'], 'The regex /<span class="highlight">[^a-z]</span>/i matches'
    assert_equal body['groups'], {"[^a-z]"=>1}

    try = { 'string' => "The lazy cat sleeps\nThe number 623 is not a cat\nThe Alaskan drives a snowcat", 'regex' => '\bcat$', 'opt' => '' }.to_json
    post '/test', try, { 'CONTENT-TYPE' => 'application/json'}
    body = JSON.parse last_response.body

    assert_equal body['match'], "The lazy cat sleeps\nThe number 623 is not a <span class=\"highlight\">cat</span>\nThe Alaskan drives a snowcat"
    assert_equal body['groups'], {"cat"=>1}

    try = { 'string' => "A loud dog", 'regex' => '^(A|The) [a-zA-Z][a-zA-Z][a-zA-Z][a-zA-Z] (dog|cat)$', 'opt' => '' }.to_json
    post '/test', try, { 'CONTENT-TYPE' => 'application/json'}
    body = JSON.parse last_response.body

    assert_equal body['match'], '<span class="highlight">A loud dog</span>'
    assert_equal body['groups'], {"[\"A\", \"dog\"]"=>1}

    try = { 'string' => "To be or not to be", 'regex' => '\bb[a-z]*e\b', 'opt' => '' }.to_json
    post '/test', try, { 'CONTENT-TYPE' => 'application/json'}
    body = JSON.parse last_response.body

    assert_equal body['match'], 'To <span class="highlight">be</span> or not to <span class="highlight">be</span>'
    assert_equal body['groups'], {"be"=> 2}   

    try = { 'string' => "What's up, doc?", 'regex' => '^.*\?$', 'opt' => '' }.to_json
    post '/test', try, { 'CONTENT-TYPE' => 'application/json'}
    body = JSON.parse last_response.body

    assert_equal body['match'], '<span class="highlight">What\'s up, doc?</span>'
    assert_equal body['groups'], {"What's up, doc?"=> 1}

    try = { 'string' => "Mississippi", 'regex' => '\b[a-z]*i[a-z]*i[a-z]*i[a-z]*\b', 'opt' => 'i' }.to_json
    post '/test', try, { 'CONTENT-TYPE' => 'application/json'}
    body = JSON.parse last_response.body

    assert_equal body['match'], "<span class=\"highlight\">Mississippi</span>"
    assert_equal body['groups'], {"Mississippi"=> 1}

    try = { 'string' => "blueberry\nblackberry\nblack berry", 'regex' => '(blue|black)berry', 'opt' => 'i' }.to_json
    post '/test', try, { 'CONTENT-TYPE' => 'application/json'}
    body = JSON.parse last_response.body

    assert_equal body['match'], "<span class=\"highlight\">blueberry</span>\n<span class=\"highlight\">blackberry</span>\nblack berry"
    assert_equal body['groups'], {"[\"blue\"]"=>1, "[\"black\"]"=>1} 

    try = { 'string' => "Hello 4567 bye CDEF - cdef", 'regex' => '\s\h\h\h\h\s', 'opt' => 'i' }.to_json
    post '/test', try, { 'CONTENT-TYPE' => 'application/json'}
    body = JSON.parse last_response.body

    assert_equal body['match'], "Hello<span class=\"highlight\"> 4567 </span>bye<span class=\"highlight\"> CDEF </span>- cdef"
    assert_equal body['groups'], {' 4567 '=> 1, ' CDEF '=> 1} 
  end
end