require_relative "../chef_data/data_normalizer"

module ChefZero
  module Endpoints
    # /organizations/ORG/policies/NAME
    class PolicyEndpoint < RestBase
      # GET /organizations/ORG/policies/NAME
      def get(request)
        revisions = list_data(request, request.rest_path + ["revisions"])
        data = { revisions: hashify_list(revisions) }
        json_response(200, data)
      end

      # DELETE /organizations/ORG/policies/NAME
      def delete(request)
        revisions = list_data(request, request.rest_path + ["revisions"])
        data = { revisions: hashify_list(revisions) }

        delete_data_dir(request, nil, :recursive)
        json_response(200, data)
      end
    end
  end
end
