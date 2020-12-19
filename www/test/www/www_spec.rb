require 'spec_helper'
require 'securerandom'
require 'ipaddr'
require 'faraday'
require 'resolv'
require 'resolv-replace'
require 'timeout'
require 'net/http'
require 'rubygems'
require 'net/http'
require 'test_utils'

describe 'www' do

  def setup_fake_hosts(hosts)
    fake_hosts = Tempfile.create('hosts')
    File.open(fake_hosts.path, 'w') do |f|
      hosts.each do |host|
        f << "#{docker_host} #{host}\n"
      end
    end

    hosts_resolver = Resolv::Hosts.new(fake_hosts.path)
    dns_resolver = Resolv::DNS.new

    Resolv::DefaultResolver.replace_resolvers([hosts_resolver, dns_resolver])
  end

  before(:all) do
    @compose ||= ComposeWrapper.new('www/docker-compose.yml')
    @compose.clean
    @compose.up('www', detached: true)
    host, port = @compose.address('www', 80)

    wait_while {
      !http_ok?(host, port)
    }

    _, ssl_port = @compose.address('www', 443)
    @base_url = "https://localhost.test:#{ssl_port}"

    setup_fake_hosts ['localhost.test']
  end

  after(:all) do
    @compose.dump_logs
    @compose.shutdown
  end

  it 'redirects regular http traffic to https' do
    _, port = @compose.address('www', 80)
    url = "http://localhost.test:#{port}"

    http = Faraday.new url, ssl: { verify: false }
    response = http.get

    assert_equal 301, response.status
    assert_equal 'https://localhost.test/', response.headers['location']
  end

  it 'answers on ssl' do
    _, port = @compose.address('www', 443)
    uri = URI::HTTPS.build(host: 'localhost.test', port: port)
    response = Net::HTTP.start(uri.host, uri.port, :use_ssl => true, :verify_mode => OpenSSL::SSL::VERIFY_NONE)
    assert_equal '/C=DE/ST=Test State or Province/L=Test Locality/O=Test Organization Name/OU=Test Organizational Unit Name/CN=localhost.test/emailAddress=info@localhost.test', response.peer_cert.subject.to_s
  end

  it 'uses index.html' do
    http = Faraday.new @base_url, ssl: { verify: false }
    response = http.get

    assert_equal 200, response.status
    assert_match '<h1>Welcome!</h1>', response.body
  end

  it 'mime type for html' do
    http = Faraday.new "#{@base_url}/index.html", ssl: { verify: false }
    response = http.get

    assert_equal 200, response.status
    assert_match 'text/html; charset=utf-8', response.headers['content-type']
  end

  it 'mime type for js' do
    http = Faraday.new "#{@base_url}/test.js", ssl: { verify: false }
    response = http.get

    assert_equal 200, response.status
    assert_match 'application/x-javascript', response.headers['content-type']
  end

  it 'mime type for css' do
    http = Faraday.new "#{@base_url}/test.css", ssl: { verify: false }
    response = http.get

    assert_equal 200, response.status
    assert_match 'text/css', response.headers['content-type']
  end
end
