module Berkshelf
  module RSpec
    module ChefAPI
      # Return an array of Hashes containing cookbooks and their information
      #
      # @return [Array]
      def get_cookbooks
        ridley.cookbook.all
      end

      def upload_cookbook(path, options = {})
        cached = CachedCookbook.from_store_path(path)

        options = {
          force: false,
          freeze: false,
          name: cached.cookbook_name,
        }.merge(options)

        ridley.cookbook.upload(cached.path, options)
      end

      # Remove the version of the given cookbook from the Chef Server defined
      # in your Knife config.
      #
      # @param [#to_s] name
      # @param [#to_s] version
      def purge_cookbook(name, version = nil)
        if version.nil?
          ridley.cookbook.delete_all(name)
        else
          ridley.cookbook.delete(name, version)
        end
      rescue Ridley::Errors::HTTPNotFound,
             Ridley::Errors::ResourceNotFound
        true
      end

      def server_has_cookbook?(name, version = nil)
        versions = ridley.cookbook.versions(name)

        if version.nil?
          !versions.empty?
        else
          !versions.find { |ver| ver == version }.nil?
        end
      rescue Ridley::Errors::HTTPNotFound,
             Ridley::Errors::ResourceNotFound
        false
      end

      def generate_cookbook(path, name, version, options = {})
        path = Pathname.new(path)
        cookbook_path = path.join("#{name}-#{version}")
        directories = [
          "recipes",
          "templates/default",
          "files/default",
          "attributes",
          "providers",
          "resources",
        ]
        files = [
          "recipes/default.rb",
          "templates/default/template.erb",
          "files/default/file.h",
          "attributes/default.rb",
        ]

        directories.each do |directory|
          FileUtils.mkdir_p(cookbook_path.join(directory))
        end

        files.each do |file|
          FileUtils.touch(cookbook_path.join(file))
        end

        metadata = [].tap do |a|
          a << "name     '#{name}'" unless options[:without_name]
          a << "version  '#{version}'"
          a << "license  '#{options[:license]}'" if options[:license]
          a << "" # ensure newline
        end.join("\n")

        if options[:dependencies]
          options[:dependencies].each do |dep_name, constraint|
            metadata << "depends '#{dep_name}', '#{constraint}'\n"
          end
        end

        if options[:recommendations]
          options[:recommendations].each do |rec_name, constraint|
            metadata << "recommends '#{rec_name}', '#{constraint}'\n"
          end
        end

        File.open(cookbook_path.join("metadata.rb"), "w+") do |f|
          f.write metadata
        end

        cookbook_path
      end

      def create_environment(environment_name)
        ridley.environment.create(name: environment_name)
      end

      def delete_environment(environment_name)
        ridley.environment.delete(environment_name)
      end

      def environment(environment_name)
        ridley.environment.find(environment_name)
      end

      def environment_exists?(environment_name)
        !environment(environment_name).nil?
      end

      private

      def ridley
        @ridley ||= Ridley.new(
          server_url: Berkshelf::RSpec::ChefServer.server_url,
          client_name: Berkshelf.chef_config[:node_name],
          client_key: Berkshelf.chef_config[:client_key],
          ssl: { verify: false }
        )
      end
    end
  end
end
