# =XMPP4R - XMPP Library for Ruby
# License:: Ruby's license (see the LICENSE file) or GNU GPL, at your option.
# Website::http://home.gna.org/xmpp4r/

require 'digest/md5'
require 'xmpp4r/base64'
require 'cgi'

module Jabber
  module SASL
	
		##
    # Class to authenticate via X-Facebook-Platform SASL mechanism.
    # To login, use this instruction: client.auth_sasl(Jabber::SASL::XFacebookPlatform.new(client, {:id => APP_ID, :token => ACCESS_TOKEN}), nil)
		class XFacebookPlatform < Base
			def initialize(stream, facebook_params)
				super(stream)

				@challenge = {}
				@facebook_params = facebook_params

				error = nil
				@stream.send(generate_auth("X-FACEBOOK-PLATFORM")) do |reply|
					if reply.name == "challenge" && reply.namespace == NS_SASL then
						@challenge = decode_challenge(reply.text)
					else
						error = reply
					end
		
					true
				end

				raise error if error.present?				
			end
	
			def decode_challenge(text)
				rv = CGI.parse(Base64.decode64(text)).symbolize_keys
				rv.each { |k, v| rv[k] = v[0] if v.is_a?(Array) }
				rv
			end
	
			def auth(password = nil)
				response_data = {
					:method => @challenge[:method],
					:api_key => @facebook_params[:id],
					:access_token => @facebook_params[:token],
					:call_id => Time.now.tv_sec,
					:v => "1.0",
					:nonce => @challenge[:nonce]
				}

				response = REXML::Element.new('response')
				response.add_namespace NS_SASL
				response.text = Base64.strict_encode64(response_data.to_query)
		
				logged = false
				error = nil
				@stream.send(response) do |reply|
					if reply.name == "success" then
						logged = true
					elsif !["challenge", "failure"].include?(reply.name) then
						error = reply
					end

					true
				end

				raise error if error.present?
				raise ClientAuthenticationFailure.new if !logged
			end
		end
	end
end