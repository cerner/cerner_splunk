require "ffi_yajl"
require_relative "cookbooks_base"

module ChefZero
  module Endpoints
    # /environment/NAME/recipes
    class EnvironmentRecipesEndpoint < CookbooksBase
      def get(request)
        environment = FFI_Yajl::Parser.parse(get_data(request, request.rest_path[0..3]))
        constraints = environment["cookbook_versions"] || {}
        result = []
        filter_cookbooks(all_cookbooks_list(request), constraints, 1) do |name, versions|
          if versions.size > 0
            cookbook = FFI_Yajl::Parser.parse(get_data(request, request.rest_path[0..1] + ["cookbooks", name, versions[0]]))
            result += recipe_names(name, cookbook)
          end
        end
        json_response(200, result.sort)
      end
    end
  end
end
