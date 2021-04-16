require "ffi_yajl"
require_relative "../rest_base"

module ChefZero
  module Endpoints
    # /organizations/NAME/authenticate_user
    class OrganizationAuthenticateUserEndpoint < RestBase
      def post(request)
        request_json = FFI_Yajl::Parser.parse(request.body)
        name = request_json["name"]
        password = request_json["password"]
        begin
          user = data_store.get(request.rest_path[0..-2] + ["users", name])
          user = FFI_Yajl::Parser.parse(user)
          verified = user["password"] == password
        rescue DataStore::DataNotFoundError
          verified = false
        end
        json_response(200, {
          "name" => name,
          "verified" => !!verified,
        })
      end
    end
  end
end
