#
# Author:: Tim Hinderliter (<tim@opscode.com>)
# Author:: Christopher Walters (<cw@opscode.com>)
# Author:: Christopher Brown (<cb@opscode.com>)
# Copyright:: Copyright (c) 2009, 2010 Opscode, Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "spec_helper"))
require "rubygems"

require "ostruct"
require "openssl"
require "mixlib/authentication/signatureverification"
require "time"
require "net/ssh"

# TODO: should make these regular spec-based mock objects.
class MockRequest
  attr_accessor :env, :params, :path, :raw_post

  def initialize(path, params, headers, raw_post)
    @path = path
    @params = params
    @env = headers
    @raw_post = raw_post
  end

  def method
    "POST"
  end
end

class MockFile
  def initialize
    @have_read = nil
  end

  def self.length
    BODY.length
  end

  def read(len, out_str)
    if @have_read.nil?
      @have_read = 1
      out_str[0..-1] = BODY
      BODY
    else
      nil
    end
  end
end

# Uncomment this to get some more info from the methods we're testing.
#Mixlib::Authentication.logger.level = :trace

describe "Mixlib::Authentication::SignedHeaderAuth" do

  # NOTE: Version 1.0 will be the default until Chef 11 is released.

  it "should generate the correct string to sign and signature, version 1.0 (default)" do

    expect(V1_0_SIGNING_OBJECT.canonicalize_request).to eq(V1_0_CANONICAL_REQUEST)

    # If you need to regenerate the constants in this test spec, print out
    # the results of res.inspect and copy them as appropriate into the
    # the constants in this file.
    expect(V1_0_SIGNING_OBJECT.sign(PRIVATE_KEY)).to eq(EXPECTED_SIGN_RESULT_V1_0)
  end

  it "should generate the correct string to sign and signature, version 1.1" do
    expect(V1_1_SIGNING_OBJECT.proto_version).to eq("1.1")
    expect(V1_1_SIGNING_OBJECT.canonicalize_request).to eq(V1_1_CANONICAL_REQUEST)

    # If you need to regenerate the constants in this test spec, print out
    # the results of res.inspect and copy them as appropriate into the
    # the constants in this file.
    expect(V1_1_SIGNING_OBJECT.sign(PRIVATE_KEY)).to eq(EXPECTED_SIGN_RESULT_V1_1)
  end

  it "should generate the correct string to sign and signature for version 1.3 with SHA256" do
    expect(V1_3_SHA256_SIGNING_OBJECT.proto_version).to eq("1.3")
    expect(V1_3_SHA256_SIGNING_OBJECT.algorithm).to eq("sha256")
    expect(V1_3_SHA256_SIGNING_OBJECT.server_api_version).to eq("1")
    expect(V1_3_SHA256_SIGNING_OBJECT.canonicalize_request).to eq(V1_3_SHA256_CANONICAL_REQUEST)

    # If you need to regenerate the constants in this test spec, print out
    # the results of res.inspect and copy them as appropriate into the
    # the constants in this file.
    expect(V1_3_SHA256_SIGNING_OBJECT.sign(PRIVATE_KEY)).to eq(EXPECTED_SIGN_RESULT_V1_3_SHA256)
  end

  it "should generate the correct string to sign and signature for version 1.3 with SHA256 via ssh-agent" do
    agent = double("ssh-agent")
    expect(Net::SSH::Authentication::Agent).to receive(:connect).and_return(agent)
    expect(agent).to receive(:sign).and_return(SSH_AGENT_RESPONSE)
    expect(V1_3_SHA256_SIGNING_OBJECT.sign(PUBLIC_KEY, use_ssh_agent: true)).to eq(EXPECTED_SIGN_RESULT_V1_3_SHA256)
  end

  it "should generate the correct string to sign and signature for non-default proto version when used as a mixin" do
    algorithm = "sha1"
    version = "1.1"

    V1_1_SIGNING_OBJECT.proto_version = "1.0"
    expect(V1_1_SIGNING_OBJECT.proto_version).to eq("1.0")
    expect(V1_1_SIGNING_OBJECT.canonicalize_request(algorithm, version)).to eq(V1_1_CANONICAL_REQUEST)

    # If you need to regenerate the constants in this test spec, print out
    # the results of res.inspect and copy them as appropriate into the
    # the constants in this file.
    expect(V1_1_SIGNING_OBJECT.sign(PRIVATE_KEY, algorithm, version)).to eq(EXPECTED_SIGN_RESULT_V1_1)
    expect(V1_1_SIGNING_OBJECT.sign(PRIVATE_KEY, sign_algorithm: algorithm, sign_version: version)).to eq(EXPECTED_SIGN_RESULT_V1_1)
  end

  it "should not choke when signing a request for a long user id with version 1.1" do
    expect { LONG_SIGNING_OBJECT.sign(PRIVATE_KEY, "sha1", "1.1") }.not_to raise_error
    expect { LONG_SIGNING_OBJECT.sign(PRIVATE_KEY, sign_algorithm: "sha1", sign_version: "1.1") }.not_to raise_error
  end

  it "should choke when signing a request for a long user id with version 1.0" do
    expect { LONG_SIGNING_OBJECT.sign(PRIVATE_KEY, "sha1", "1.0") }.to raise_error(OpenSSL::PKey::RSAError)
    expect { LONG_SIGNING_OBJECT.sign(PRIVATE_KEY, sign_algorithm: "sha1", sign_version: "1.0") }.to raise_error(OpenSSL::PKey::RSAError)
  end

  it "should choke when signing a request with a bad version" do
    expect { V1_1_SIGNING_OBJECT.sign(PRIVATE_KEY, "sha1", "poo") }.to raise_error(Mixlib::Authentication::AuthenticationError)
  end

  it "should choke when signing a request with a bad algorithm" do
    expect { V1_1_SIGNING_OBJECT.sign(PRIVATE_KEY, "sha_poo", "1.1") }.to raise_error(Mixlib::Authentication::AuthenticationError)
  end

  it "should choke when signing a request via ssh-agent and ssh-agent is not reachable with version 1.3" do
    expect(Net::SSH::Authentication::Agent).to receive(:connect).and_raise(Net::SSH::Authentication::AgentNotAvailable)
    expect { V1_3_SHA256_SIGNING_OBJECT.sign(PUBLIC_KEY, use_ssh_agent: true) }.to raise_error(Mixlib::Authentication::AuthenticationError)
  end

  it "should choke when signing a request via ssh-agent and the key is not loaded with version 1.3" do
    agent = double("ssh-agent")
    expect(Net::SSH::Authentication::Agent).to receive(:connect).and_return(agent)
    expect(agent).to receive(:sign).and_raise(Net::SSH::Authentication::AgentError)
    expect { V1_3_SHA256_SIGNING_OBJECT.sign(PUBLIC_KEY, use_ssh_agent: true) }.to raise_error(Mixlib::Authentication::AuthenticationError)
  end

end

describe "Mixlib::Authentication::SignatureVerification" do

  before(:each) do
    @user_private_key = PRIVATE_KEY
  end

  it "should authenticate a File-containing request V1.1 - Merb" do
    request_params = MERB_REQUEST_PARAMS.clone
    request_params["file"] =
      { "size" => MockFile.length, "content_type" => "application/octet-stream", "filename" => "zsh.tar.gz", "tempfile" => MockFile.new }

    mock_request = MockRequest.new(PATH, request_params, MERB_HEADERS_V1_1, "")
    expect(Time).to receive(:now).at_least(:once).and_return(TIMESTAMP_OBJ)

    service = Mixlib::Authentication::SignatureVerification.new
    res = service.authenticate_user_request(mock_request, @user_private_key)
    expect(res).not_to be_nil
  end

  it "should authenticate a File-containing request V1.3 SHA256 - Merb" do
    request_params = MERB_REQUEST_PARAMS.clone
    request_params["file"] =
      { "size" => MockFile.length, "content_type" => "application/octet-stream", "filename" => "zsh.tar.gz", "tempfile" => MockFile.new }

    mock_request = MockRequest.new(PATH, request_params, MERB_HEADERS_V1_3_SHA256, "")
    expect(Time).to receive(:now).at_least(:once).and_return(TIMESTAMP_OBJ)

    service = Mixlib::Authentication::SignatureVerification.new
    res = service.authenticate_user_request(mock_request, @user_private_key)
    expect(res).not_to be_nil
  end

  it "should authenticate a File-containing request from a v1.0 client - Passenger" do
    request_params = PASSENGER_REQUEST_PARAMS.clone
    request_params["tarball"] = MockFile.new

    mock_request = MockRequest.new(PATH, request_params, PASSENGER_HEADERS_V1_0, "")
    expect(Time).to receive(:now).at_least(:once).and_return(TIMESTAMP_OBJ)

    auth_req = Mixlib::Authentication::SignatureVerification.new
    res = auth_req.authenticate_user_request(mock_request, @user_private_key)
    expect(res).not_to be_nil
  end

  it "should authenticate a normal (post body) request v1.3 SHA256 - Merb" do
    mock_request = MockRequest.new(PATH, MERB_REQUEST_PARAMS, MERB_HEADERS_V1_3_SHA256, BODY)
    expect(Time).to receive(:now).at_least(:once).and_return(TIMESTAMP_OBJ)

    service = Mixlib::Authentication::SignatureVerification.new
    res = service.authenticate_user_request(mock_request, @user_private_key)
    expect(res).not_to be_nil
  end

  it "should authenticate a normal (post body) request v1.1 - Merb" do
    mock_request = MockRequest.new(PATH, MERB_REQUEST_PARAMS, MERB_HEADERS_V1_1, BODY)
    expect(Time).to receive(:now).at_least(:once).and_return(TIMESTAMP_OBJ)

    service = Mixlib::Authentication::SignatureVerification.new
    res = service.authenticate_user_request(mock_request, @user_private_key)
    expect(res).not_to be_nil
  end

  it "should authenticate a normal (post body) request from a v1.0 client - Merb" do
    mock_request = MockRequest.new(PATH, MERB_REQUEST_PARAMS, MERB_HEADERS_V1_0, BODY)
    expect(Time).to receive(:now).at_least(:once).and_return(TIMESTAMP_OBJ)

    service = Mixlib::Authentication::SignatureVerification.new
    res = service.authenticate_user_request(mock_request, @user_private_key)
    expect(res).not_to be_nil
  end

  it "shouldn't authenticate if an Authorization header is missing" do
    headers = MERB_HEADERS_V1_1.clone
    headers.delete("HTTP_X_OPS_SIGN")

    mock_request = MockRequest.new(PATH, MERB_REQUEST_PARAMS, headers, BODY)
    allow(Time).to receive(:now).and_return(TIMESTAMP_OBJ)
    #Time.stub!(:now).and_return(TIMESTAMP_OBJ)

    auth_req = Mixlib::Authentication::SignatureVerification.new
    expect { auth_req.authenticate_user_request(mock_request, @user_private_key) }.to raise_error(Mixlib::Authentication::AuthenticationError)

    expect(auth_req).not_to be_a_valid_request
    expect(auth_req).not_to be_a_valid_timestamp
    expect(auth_req).not_to be_a_valid_signature
    expect(auth_req).not_to be_a_valid_content_hash
  end

  it "shouldn't authenticate if Authorization header is wrong" do
    headers = MERB_HEADERS_V1_1.clone
    headers["HTTP_X_OPS_CONTENT_HASH"] += "_"

    mock_request = MockRequest.new(PATH, MERB_REQUEST_PARAMS, headers, BODY)
    expect(Time).to receive(:now).at_least(:once).and_return(TIMESTAMP_OBJ)

    auth_req = Mixlib::Authentication::SignatureVerification.new
    res = auth_req.authenticate_user_request(mock_request, @user_private_key)
    expect(res).to be_nil

    expect(auth_req).not_to be_a_valid_request
    expect(auth_req).to be_a_valid_timestamp
    expect(auth_req).to be_a_valid_signature
    expect(auth_req).not_to be_a_valid_content_hash
  end

  it "shouldn't authenticate if the timestamp is not within bounds" do
    mock_request = MockRequest.new(PATH, MERB_REQUEST_PARAMS, MERB_HEADERS_V1_1, BODY)
    expect(Time).to receive(:now).at_least(:once).and_return(TIMESTAMP_OBJ - 1000)

    auth_req = Mixlib::Authentication::SignatureVerification.new
    res = auth_req.authenticate_user_request(mock_request, @user_private_key)
    expect(res).to be_nil
    expect(auth_req).not_to be_a_valid_request
    expect(auth_req).not_to be_a_valid_timestamp
    expect(auth_req).to be_a_valid_signature
    expect(auth_req).to be_a_valid_content_hash
  end

  it "shouldn't authenticate if the signature is wrong" do
    headers = MERB_HEADERS_V1_1.dup
    headers["HTTP_X_OPS_AUTHORIZATION_1"] = "epicfail"
    mock_request = MockRequest.new(PATH, MERB_REQUEST_PARAMS, headers, BODY)
    expect(Time).to receive(:now).at_least(:once).and_return(TIMESTAMP_OBJ)

    auth_req = Mixlib::Authentication::SignatureVerification.new
    res = auth_req.authenticate_user_request(mock_request, @user_private_key)
    expect(res).to be_nil
    expect(auth_req).not_to be_a_valid_request
    expect(auth_req).not_to be_a_valid_signature
    expect(auth_req).to be_a_valid_timestamp
    expect(auth_req).to be_a_valid_content_hash
  end

  it "shouldn't authenticate if the signature is wrong for v1.3 SHA256" do
    headers = MERB_HEADERS_V1_3_SHA256.dup
    headers["HTTP_X_OPS_AUTHORIZATION_1"] = "epicfail"
    mock_request = MockRequest.new(PATH, MERB_REQUEST_PARAMS, headers, BODY)
    expect(Time).to receive(:now).at_least(:once).and_return(TIMESTAMP_OBJ)

    auth_req = Mixlib::Authentication::SignatureVerification.new
    res = auth_req.authenticate_user_request(mock_request, @user_private_key)
    expect(res).to be_nil
    expect(auth_req).not_to be_a_valid_request
    expect(auth_req).not_to be_a_valid_signature
    expect(auth_req).to be_a_valid_timestamp
    expect(auth_req).to be_a_valid_content_hash
  end
end

USER_ID = "spec-user"
DIGESTED_USER_ID = Base64.encode64(Digest::SHA1.new.digest(USER_ID)).chomp
BODY = "Spec Body"
HASHED_BODY = "DFteJZPVv6WKdQmMqZUQUumUyRs=" # Base64.encode64(Digest::SHA1.digest("Spec Body")).chomp
HASHED_BODY_SHA256 = "hDlKNZhIhgso3Fs0S0pZwJ0xyBWtR1RBaeHs1DrzOho="
TIMESTAMP_ISO8601 = "2009-01-01T12:00:00Z"
TIMESTAMP_OBJ = Time.parse("Thu Jan 01 12:00:00 -0000 2009")
PATH = "/organizations/clownco"
HASHED_CANONICAL_PATH = "YtBWDn1blGGuFIuKksdwXzHU9oE=" # Base64.encode64(Digest::SHA1.digest("/organizations/clownco")).chomp

V1_0_ARGS = {
  :body => BODY,
  :user_id => USER_ID,
  :http_method => :post,
  :timestamp => TIMESTAMP_ISO8601,    # fixed timestamp so we get back the same answer each time.
  :file => MockFile.new,
  :path => PATH,
}

V1_1_ARGS = {
  :body => BODY,
  :user_id => USER_ID,
  :http_method => :post,
  :timestamp => TIMESTAMP_ISO8601,    # fixed timestamp so we get back the same answer each time.
  :file => MockFile.new,
  :path => PATH,
  :proto_version => 1.1,
}

V1_3_ARGS_SHA256 = {
  :body => BODY,
  :user_id => USER_ID,
  :http_method => :post,
  :timestamp => TIMESTAMP_ISO8601,    # fixed timestamp so we get back the same answer each time.
  :file => MockFile.new,
  :path => PATH,
  :proto_version => "1.3",
  :headers => {
    "X-OpS-SeRvEr-ApI-VerSiOn" => "1",
  }
  # This defaults to sha256
}

LONG_PATH_LONG_USER_ARGS = {
  :body => BODY,
  :user_id => "A" * 200,
  :http_method => :put,
  :timestamp => TIMESTAMP_ISO8601, # fixed timestamp so we get back the same answer each time.
  :file => MockFile.new,
  :path => PATH + "/nodes/#{"A" * 250}",
}

REQUESTING_ACTOR_ID = "c0f8a68c52bffa1020222a56b23cccfa"

# Content hash is ???TODO
X_OPS_CONTENT_HASH = "DFteJZPVv6WKdQmMqZUQUumUyRs="
X_OPS_CONTENT_HASH_SHA256 = "hDlKNZhIhgso3Fs0S0pZwJ0xyBWtR1RBaeHs1DrzOho="

X_OPS_AUTHORIZATION_LINES_V1_0 = [
"jVHrNniWzpbez/eGWjFnO6lINRIuKOg40ZTIQudcFe47Z9e/HvrszfVXlKG4",
"NMzYZgyooSvU85qkIUmKuCqgG2AIlvYa2Q/2ctrMhoaHhLOCWWoqYNMaEqPc",
"3tKHE+CfvP+WuPdWk4jv4wpIkAz6ZLxToxcGhXmZbXpk56YTmqgBW2cbbw4O",
"IWPZDHSiPcw//AYNgW1CCDptt+UFuaFYbtqZegcBd2n/jzcWODA7zL4KWEUy",
"9q4rlh/+1tBReg60QdsmDRsw/cdO1GZrKtuCwbuD4+nbRdVBKv72rqHX9cu0",
"utju9jzczCyB+sSAQWrxSsXB/b8vV2qs0l4VD2ML+w==",
]

X_OPS_AUTHORIZATION_LINES = [
"UfZD9dRz6rFu6LbP5Mo1oNHcWYxpNIcUfFCffJS1FQa0GtfU/vkt3/O5HuCM",
"1wIFl/U0f5faH9EWpXWY5NwKR031Myxcabw4t4ZLO69CIh/3qx1XnjcZvt2w",
"c2R9bx/43IWA/r8w8Q6decuu0f6ZlNheJeJhaYPI8piX/aH+uHBH8zTACZu8",
"vMnl5MF3/OIlsZc8cemq6eKYstp8a8KYq9OmkB5IXIX6qVMJHA6fRvQEB/7j",
"281Q7oI/O+lE8AmVyBbwruPb7Mp6s4839eYiOdjbDwFjYtbS3XgAjrHlaD7W",
"FDlbAG7H8Dmvo+wBxmtNkszhzbBnEYtuwQqT8nM/8A==",
]

X_OPS_AUTHORIZATION_LINES_V1_3_SHA256 = [
  "FZOmXAyOBAZQV/uw188iBljBJXOm+m8xQ/8KTGLkgGwZNcRFxk1m953XjE3W",
  "VGy1dFT76KeaNWmPCNtDmprfH2na5UZFtfLIKrPv7xm80V+lzEzTd9WBwsfP",
  "42dZ9N+V9I5SVfcL/lWrrlpdybfceJC5jOcP5tzfJXWUITwb6Z3Erg3DU3Uh",
  "H9h9E0qWlYGqmiNCVrBnpe6Si1gU/Jl+rXlRSNbLJ4GlArAPuL976iTYJTzE",
  "MmbLUIm3JRYi00Yb01IUCCKdI90vUq1HHNtlTEu93YZfQaJwRxXlGkCNwIJe",
  "fy49QzaCIEu1XiOx5Jn+4GmkrZch/RrK9VzQWXgs+w==",
]

SSH_AGENT_RESPONSE = "\x00\x00\x00\frsa-sha2-256\x00\x00\x01\x00\x15\x93\xA6\\\f\x8E\x04\x06PW\xFB\xB0\xD7\xCF\"\x06X\xC1%s\xA6\xFAo1C\xFF\nLb\xE4\x80l\x195\xC4E\xC6Mf\xF7\x9D\xD7\x8CM\xD6Tl\xB5tT\xFB\xE8\xA7\x9A5i\x8F\b\xDBC\x9A\x9A\xDF\x1Fi\xDA\xE5FE\xB5\xF2\xC8*\xB3\xEF\xEF\x19\xBC\xD1_\xA5\xCCL\xD3w\xD5\x81\xC2\xC7\xCF\xE3gY\xF4\xDF\x95\xF4\x8ERU\xF7\v\xFEU\xAB\xAEZ]\xC9\xB7\xDCx\x90\xB9\x8C\xE7\x0F\xE6\xDC\xDF%u\x94!<\e\xE9\x9D\xC4\xAE\r\xC3Su!\x1F\xD8}\x13J\x96\x95\x81\xAA\x9A#BV\xB0g\xA5\xEE\x92\x8BX\x14\xFC\x99~\xADyQH\xD6\xCB'\x81\xA5\x02\xB0\x0F\xB8\xBF{\xEA$\xD8%<\xC42f\xCBP\x89\xB7%\x16\"\xD3F\e\xD3R\x14\b\"\x9D#\xDD/R\xADG\x1C\xDBeLK\xBD\xDD\x86_A\xA2pG\x15\xE5\x1A@\x8D\xC0\x82^\x7F.=C6\x82 K\xB5^#\xB1\xE4\x99\xFE\xE0i\xA4\xAD\x97!\xFD\x1A\xCA\xF5\\\xD0Yx,\xFB"
# We expect Mixlib::Authentication::SignedHeaderAuth#sign to return this
# if passed the BODY above, based on version

EXPECTED_SIGN_RESULT_V1_0 = {
  "X-Ops-Content-Hash" => X_OPS_CONTENT_HASH,
  "X-Ops-Userid" => USER_ID,
  "X-Ops-Sign" => "algorithm=sha1;version=1.0;",
  "X-Ops-Authorization-1" => X_OPS_AUTHORIZATION_LINES_V1_0[0],
  "X-Ops-Authorization-2" => X_OPS_AUTHORIZATION_LINES_V1_0[1],
  "X-Ops-Authorization-3" => X_OPS_AUTHORIZATION_LINES_V1_0[2],
  "X-Ops-Authorization-4" => X_OPS_AUTHORIZATION_LINES_V1_0[3],
  "X-Ops-Authorization-5" => X_OPS_AUTHORIZATION_LINES_V1_0[4],
  "X-Ops-Authorization-6" => X_OPS_AUTHORIZATION_LINES_V1_0[5],
  "X-Ops-Timestamp" => TIMESTAMP_ISO8601,
}

EXPECTED_SIGN_RESULT_V1_1 = {
  "X-Ops-Content-Hash" => X_OPS_CONTENT_HASH,
  "X-Ops-Userid" => USER_ID,
  "X-Ops-Sign" => "algorithm=sha1;version=1.1;",
  "X-Ops-Authorization-1" => X_OPS_AUTHORIZATION_LINES[0],
  "X-Ops-Authorization-2" => X_OPS_AUTHORIZATION_LINES[1],
  "X-Ops-Authorization-3" => X_OPS_AUTHORIZATION_LINES[2],
  "X-Ops-Authorization-4" => X_OPS_AUTHORIZATION_LINES[3],
  "X-Ops-Authorization-5" => X_OPS_AUTHORIZATION_LINES[4],
  "X-Ops-Authorization-6" => X_OPS_AUTHORIZATION_LINES[5],
  "X-Ops-Timestamp" => TIMESTAMP_ISO8601,
}

EXPECTED_SIGN_RESULT_V1_3_SHA256 = {
  "X-Ops-Content-Hash" => X_OPS_CONTENT_HASH_SHA256,
  "X-Ops-Userid" => USER_ID,
  "X-Ops-Sign" => "algorithm=sha256;version=1.3;",
  "X-Ops-Authorization-1" => X_OPS_AUTHORIZATION_LINES_V1_3_SHA256[0],
  "X-Ops-Authorization-2" => X_OPS_AUTHORIZATION_LINES_V1_3_SHA256[1],
  "X-Ops-Authorization-3" => X_OPS_AUTHORIZATION_LINES_V1_3_SHA256[2],
  "X-Ops-Authorization-4" => X_OPS_AUTHORIZATION_LINES_V1_3_SHA256[3],
  "X-Ops-Authorization-5" => X_OPS_AUTHORIZATION_LINES_V1_3_SHA256[4],
  "X-Ops-Authorization-6" => X_OPS_AUTHORIZATION_LINES_V1_3_SHA256[5],
  "X-Ops-Timestamp" => TIMESTAMP_ISO8601,
}

OTHER_HEADERS = {
  # An arbitrary sampling of non-HTTP_* headers are in here to
  # exercise that code path.
  "REMOTE_ADDR" => "127.0.0.1",
  "PATH_INFO" => "/organizations/local-test-org/cookbooks",
  "REQUEST_PATH" => "/organizations/local-test-org/cookbooks",
  "CONTENT_TYPE" => "multipart/form-data; boundary=----RubyMultipartClient6792ZZZZZ",
  "CONTENT_LENGTH" => "394",
}

# This is what will be in request.params for the Merb case.
MERB_REQUEST_PARAMS = {
  "name" => "zsh", "action" => "create", "controller" => "chef_server_api/cookbooks",
  "organization_id" => "local-test-org", "requesting_actor_id" => REQUESTING_ACTOR_ID
}

MERB_HEADERS_V1_3_SHA256 = {
  # These are used by signatureverification.
  "HTTP_HOST" => "127.0.0.1",
  "HTTP_X_OPS_SIGN" => "algorithm=sha256;version=1.3;",
  "HTTP_X_OPS_REQUESTID" => "127.0.0.1 1258566194.85386",
  "HTTP_X_OPS_TIMESTAMP" => TIMESTAMP_ISO8601,
  "HTTP_X_OPS_CONTENT_HASH" => X_OPS_CONTENT_HASH_SHA256,
  "HTTP_X_OPS_USERID" => USER_ID,
  "HTTP_X_OPS_SERVER_API_VERSION" => "1",
  "HTTP_X_OPS_AUTHORIZATION_1" => X_OPS_AUTHORIZATION_LINES_V1_3_SHA256[0],
  "HTTP_X_OPS_AUTHORIZATION_2" => X_OPS_AUTHORIZATION_LINES_V1_3_SHA256[1],
  "HTTP_X_OPS_AUTHORIZATION_3" => X_OPS_AUTHORIZATION_LINES_V1_3_SHA256[2],
  "HTTP_X_OPS_AUTHORIZATION_4" => X_OPS_AUTHORIZATION_LINES_V1_3_SHA256[3],
  "HTTP_X_OPS_AUTHORIZATION_5" => X_OPS_AUTHORIZATION_LINES_V1_3_SHA256[4],
  "HTTP_X_OPS_AUTHORIZATION_6" => X_OPS_AUTHORIZATION_LINES_V1_3_SHA256[5],
}.merge(OTHER_HEADERS)

# Tis is what will be in request.env for the Merb case.
MERB_HEADERS_V1_1 = {
  # These are used by signatureverification.
  "HTTP_HOST" => "127.0.0.1",
  "HTTP_X_OPS_SIGN" => "algorithm=sha1;version=1.1;",
  "HTTP_X_OPS_REQUESTID" => "127.0.0.1 1258566194.85386",
  "HTTP_X_OPS_TIMESTAMP" => TIMESTAMP_ISO8601,
  "HTTP_X_OPS_CONTENT_HASH" => X_OPS_CONTENT_HASH,
  "HTTP_X_OPS_USERID" => USER_ID,
  "HTTP_X_OPS_AUTHORIZATION_1" => X_OPS_AUTHORIZATION_LINES[0],
  "HTTP_X_OPS_AUTHORIZATION_2" => X_OPS_AUTHORIZATION_LINES[1],
  "HTTP_X_OPS_AUTHORIZATION_3" => X_OPS_AUTHORIZATION_LINES[2],
  "HTTP_X_OPS_AUTHORIZATION_4" => X_OPS_AUTHORIZATION_LINES[3],
  "HTTP_X_OPS_AUTHORIZATION_5" => X_OPS_AUTHORIZATION_LINES[4],
  "HTTP_X_OPS_AUTHORIZATION_6" => X_OPS_AUTHORIZATION_LINES[5],
}.merge(OTHER_HEADERS)

# Tis is what will be in request.env for the Merb case.
MERB_HEADERS_V1_0 = {
  # These are used by signatureverification.
  "HTTP_HOST" => "127.0.0.1",
  "HTTP_X_OPS_SIGN" => "version=1.0",
  "HTTP_X_OPS_REQUESTID" => "127.0.0.1 1258566194.85386",
  "HTTP_X_OPS_TIMESTAMP" => TIMESTAMP_ISO8601,
  "HTTP_X_OPS_CONTENT_HASH" => X_OPS_CONTENT_HASH,
  "HTTP_X_OPS_USERID" => USER_ID,
  "HTTP_X_OPS_AUTHORIZATION_1" => X_OPS_AUTHORIZATION_LINES_V1_0[0],
  "HTTP_X_OPS_AUTHORIZATION_2" => X_OPS_AUTHORIZATION_LINES_V1_0[1],
  "HTTP_X_OPS_AUTHORIZATION_3" => X_OPS_AUTHORIZATION_LINES_V1_0[2],
  "HTTP_X_OPS_AUTHORIZATION_4" => X_OPS_AUTHORIZATION_LINES_V1_0[3],
  "HTTP_X_OPS_AUTHORIZATION_5" => X_OPS_AUTHORIZATION_LINES_V1_0[4],
  "HTTP_X_OPS_AUTHORIZATION_6" => X_OPS_AUTHORIZATION_LINES_V1_0[5],
}.merge(OTHER_HEADERS)

PASSENGER_REQUEST_PARAMS = {
  "action" => "create",
  #"tarball"=>#<File:/tmp/RackMultipart20091120-25570-mgq2sa-0>,
  "controller" => "api/v1/cookbooks",
  "cookbook" => "{\"category\":\"databases\"}",
}

PASSENGER_HEADERS_V1_1 = {
  # These are used by signatureverification.
  "HTTP_HOST" => "127.0.0.1",
  "HTTP_X_OPS_SIGN" => "algorithm=sha1;version=1.1;",
  "HTTP_X_OPS_REQUESTID" => "127.0.0.1 1258566194.85386",
  "HTTP_X_OPS_TIMESTAMP" => TIMESTAMP_ISO8601,
  "HTTP_X_OPS_CONTENT_HASH" => X_OPS_CONTENT_HASH,
  "HTTP_X_OPS_USERID" => USER_ID,
  "HTTP_X_OPS_AUTHORIZATION_1" => X_OPS_AUTHORIZATION_LINES[0],
  "HTTP_X_OPS_AUTHORIZATION_2" => X_OPS_AUTHORIZATION_LINES[1],
  "HTTP_X_OPS_AUTHORIZATION_3" => X_OPS_AUTHORIZATION_LINES[2],
  "HTTP_X_OPS_AUTHORIZATION_4" => X_OPS_AUTHORIZATION_LINES[3],
  "HTTP_X_OPS_AUTHORIZATION_5" => X_OPS_AUTHORIZATION_LINES[4],
  "HTTP_X_OPS_AUTHORIZATION_6" => X_OPS_AUTHORIZATION_LINES[5],
}.merge(OTHER_HEADERS)

PASSENGER_HEADERS_V1_0 = {
  # These are used by signatureverification.
  "HTTP_HOST" => "127.0.0.1",
  "HTTP_X_OPS_SIGN" => "version=1.0",
  "HTTP_X_OPS_REQUESTID" => "127.0.0.1 1258566194.85386",
  "HTTP_X_OPS_TIMESTAMP" => TIMESTAMP_ISO8601,
  "HTTP_X_OPS_CONTENT_HASH" => X_OPS_CONTENT_HASH,
  "HTTP_X_OPS_USERID" => USER_ID,
  "HTTP_X_OPS_AUTHORIZATION_1" => X_OPS_AUTHORIZATION_LINES_V1_0[0],
  "HTTP_X_OPS_AUTHORIZATION_2" => X_OPS_AUTHORIZATION_LINES_V1_0[1],
  "HTTP_X_OPS_AUTHORIZATION_3" => X_OPS_AUTHORIZATION_LINES_V1_0[2],
  "HTTP_X_OPS_AUTHORIZATION_4" => X_OPS_AUTHORIZATION_LINES_V1_0[3],
  "HTTP_X_OPS_AUTHORIZATION_5" => X_OPS_AUTHORIZATION_LINES_V1_0[4],
  "HTTP_X_OPS_AUTHORIZATION_6" => X_OPS_AUTHORIZATION_LINES_V1_0[5],
}.merge(OTHER_HEADERS)

# generated with
#   openssl genrsa -out private.pem 2048
#   openssl rsa -in private.pem -out public.pem -pubout
PUBLIC_KEY_DATA = <<EOS
-----BEGIN PUBLIC KEY-----
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA0ueqo76MXuP6XqZBILFz
iH/9AI7C6PaN5W0dSvkr9yInyGHSz/IR1+4tqvP2qlfKVKI4CP6BFH251Ft9qMUB
uAsnlAVQ1z0exDtIFFOyQCdR7iXmjBIWMSS4buBwRQXwDK7id1OxtU23qVJv+xwE
V0IzaaSJmaGLIbvRBD+qatfUuQJBMU/04DdJIwvLtZBYdC2219m5dUBQaa4bimL+
YN9EcsDzD9h9UxQo5ReK7b3cNMzJBKJWLzFBcJuePMzAnLFktr/RufX4wpXe6XJx
oVPaHo72GorLkwnQ0HYMTY8rehT4mDi1FI969LHCFFaFHSAaRnwdXaQkJmSfcxzC
YQIDAQAB
-----END PUBLIC KEY-----
EOS

PUBLIC_KEY = OpenSSL::PKey::RSA.new(PUBLIC_KEY_DATA)

PRIVATE_KEY_DATA = <<EOS
-----BEGIN RSA PRIVATE KEY-----
MIIEpAIBAAKCAQEA0ueqo76MXuP6XqZBILFziH/9AI7C6PaN5W0dSvkr9yInyGHS
z/IR1+4tqvP2qlfKVKI4CP6BFH251Ft9qMUBuAsnlAVQ1z0exDtIFFOyQCdR7iXm
jBIWMSS4buBwRQXwDK7id1OxtU23qVJv+xwEV0IzaaSJmaGLIbvRBD+qatfUuQJB
MU/04DdJIwvLtZBYdC2219m5dUBQaa4bimL+YN9EcsDzD9h9UxQo5ReK7b3cNMzJ
BKJWLzFBcJuePMzAnLFktr/RufX4wpXe6XJxoVPaHo72GorLkwnQ0HYMTY8rehT4
mDi1FI969LHCFFaFHSAaRnwdXaQkJmSfcxzCYQIDAQABAoIBAQCW3I4sKN5B9jOe
xq/pkeWBq4OvhW8Ys1yW0zFT8t6nHbB1XrwscQygd8gE9BPqj3e0iIEqtdphbPmj
VHqTYbC0FI6QDClifV7noTwTBjeIOlgZ0NSUN0/WgVzIOxUz2mZ2vBZUovKILPqG
TOi7J7RXMoySMdcXpP1f+PgvYNcnKsT72UcWaSXEV8/zo+Zm/qdGPVWwJonri5Mp
DVm5EQSENBiRyt028rU6ElXORNmoQpVjDVqZ1gipzXkifdjGyENw2rt4V/iKYD7V
5iqXOsvP6Cemf4gbrjunAgDG08S00kiUgvVWcdXW+dlsR2nCvH4DOEe3AYYh/aH8
DxEE7FbtAoGBAPcNO8fJ56mNw0ow4Qg38C+Zss/afhBOCfX4O/SZKv/roRn5+gRM
KRJYSVXNnsjPI1plzqR4OCyOrjAhtuvL4a0DinDzf1+fiztyNohwYsW1vYmqn3ti
EN0GhSgE7ppZjqvLQ3f3LUTxynhA0U+k9wflb4irIlViTUlCsOPkrNJDAoGBANqL
Q+vvuGSsmRLU/Cenjy+Mjj6+QENg51dz34o8JKuVKIPKU8pNnyeLa5fat0qD2MHm
OB9opeQOcw0dStodxr6DB3wi83bpjeU6BWUGITNiWEaZEBrQ0aiqNJJKrrHm8fAZ
9o4l4oHc4hI0kYVYYDuxtKuVJrzZiEapTwoOcYiLAoGBAI/EWbeIHZIj9zOjgjEA
LHvm25HtulLOtyk2jd1njQhlHNk7CW2azIPqcLLH99EwCYi/miNH+pijZ2aHGCXb
/bZrSxM0ADmrZKDxdB6uGCyp+GS2sBxjEyEsfCyvwhJ8b3Q100tqwiNO+d5FCglp
HICx2dgUjuRVUliBwOK93nx1AoGAUI8RhIEjOYkeDAESyhNMBr0LGjnLOosX+/as
qiotYkpjWuFULbibOFp+WMW41vDvD9qrSXir3fstkeIAW5KqVkO6mJnRoT3Knnra
zjiKOITCAZQeiaP8BO5o3pxE9TMqb9VCO3ffnPstIoTaN4syPg7tiGo8k1SklVeH
2S8lzq0CgYAKG2fljIYWQvGH628rp4ZcXS4hWmYohOxsnl1YrszbJ+hzR+IQOhGl
YlkUQYXhy9JixmUUKtH+NXkKX7Lyc8XYw5ETr7JBT3ifs+G7HruDjVG78EJVojbd
8uLA+DdQm5mg4vd1GTiSK65q/3EeoBlUaVor3HhLFki+i9qpT8CBsg==
-----END RSA PRIVATE KEY-----
EOS

PRIVATE_KEY = OpenSSL::PKey::RSA.new(PRIVATE_KEY_DATA)

V1_0_CANONICAL_REQUEST_DATA = <<EOS
Method:POST
Hashed Path:#{HASHED_CANONICAL_PATH}
X-Ops-Content-Hash:#{HASHED_BODY}
X-Ops-Timestamp:#{TIMESTAMP_ISO8601}
X-Ops-UserId:#{USER_ID}
EOS
V1_0_CANONICAL_REQUEST = V1_0_CANONICAL_REQUEST_DATA.chomp

V1_1_CANONICAL_REQUEST_DATA = <<EOS
Method:POST
Hashed Path:#{HASHED_CANONICAL_PATH}
X-Ops-Content-Hash:#{HASHED_BODY}
X-Ops-Timestamp:#{TIMESTAMP_ISO8601}
X-Ops-UserId:#{DIGESTED_USER_ID}
EOS
V1_1_CANONICAL_REQUEST = V1_1_CANONICAL_REQUEST_DATA.chomp

V1_3_SHA256_CANONICAL_REQUEST_DATA = <<EOS
Method:POST
Path:#{PATH}
X-Ops-Content-Hash:#{HASHED_BODY_SHA256}
X-Ops-Sign:version=1.3
X-Ops-Timestamp:#{TIMESTAMP_ISO8601}
X-Ops-UserId:#{USER_ID}
X-Ops-Server-API-Version:1
EOS
V1_3_SHA256_CANONICAL_REQUEST = V1_3_SHA256_CANONICAL_REQUEST_DATA.chomp

V1_3_SHA256_SIGNING_OBJECT = Mixlib::Authentication::SignedHeaderAuth.signing_object(V1_3_ARGS_SHA256)
V1_1_SIGNING_OBJECT = Mixlib::Authentication::SignedHeaderAuth.signing_object(V1_1_ARGS)
V1_0_SIGNING_OBJECT = Mixlib::Authentication::SignedHeaderAuth.signing_object(V1_0_ARGS)
LONG_SIGNING_OBJECT = Mixlib::Authentication::SignedHeaderAuth.signing_object(LONG_PATH_LONG_USER_ARGS)
