require "ffi_yajl"
require_relative "../rest_base"
require_relative "../chef_data/data_normalizer"

module ChefZero
  module Endpoints
    # Common code for endpoints that return cookbook lists
    class CookbooksBase < RestBase
      def format_cookbooks_list(request, cookbooks_list, constraints = {}, num_versions = nil)
        results = {}
        filter_cookbooks(cookbooks_list, constraints, num_versions) do |name, versions|
          versions_list = versions.map do |version|
            {
              "url" => build_uri(request.base_uri, request.rest_path[0..1] + ["cookbooks", name, version]),
              "version" => version,
            }
          end
          results[name] = {
            "url" => build_uri(request.base_uri, request.rest_path[0..1] + ["cookbooks", name]),
            "versions" => versions_list,
          }
        end
        results
      end

      def format_universe_list(request, cookbooks_list)
        results = {}
        cookbooks_list.each do |name, versions|
          results[name] ||= {}
          versions.each do |version|
            cookbook_data = FFI_Yajl::Parser.parse(get_data(request, request.rest_path[0..1] + [ "cookbooks", name, version ], :nil))
            results[name][version] ||= {
              "dependencies" => cookbook_data["metadata"]["dependencies"],
              "location_path" => build_uri(request.base_uri, request.rest_path[0..1] + ["cookbooks", name, version]),
              "location_type" => "chef_server",
            }
          end
        end
        results
      end

      def all_cookbooks_list(request)
        result = {}
        # Race conditions exist here (if someone deletes while listing).  I don't care.
        data_store.list(request.rest_path[0..1] + ["cookbooks"]).each do |name|
          result[name] = data_store.list(request.rest_path[0..1] + ["cookbooks", name])
        end
        result
      end

      def filter_cookbooks(cookbooks_list, constraints = {}, num_versions = nil)
        cookbooks_list.keys.sort.each do |name|
          constraint = Gem::Requirement.new(constraints[name])
          versions = []
          cookbooks_list[name].sort_by { |version| Gem::Version.new(version.dup) }.reverse_each do |version|
            break if num_versions && versions.size >= num_versions

            if constraint.satisfied_by?(Gem::Version.new(version.dup))
              versions << version
            end
          end
          yield [name, versions]
        end
      end

      def recipe_names(cookbook_name, cookbook)
        cookbook["all_files"].inject([]) do |acc, file|
          part, name = file["name"].split("/")
          next acc unless part == "recipes" || File.extname(name) != ".rb"

          if name == "default.rb"
            acc << cookbook_name
          else
            acc << "#{cookbook_name}::#{File.basename(name, ".rb")}"
          end
        end
      end
    end
  end
end
