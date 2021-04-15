class Chef
  module Sugar
    module Filters
      #
      # Evaluate resources at compile time instead of converge time.
      #
      class AtCompileTime
        def initialize(recipe)
          @recipe = recipe
        end

        def evaluate(&block)
          instance_eval(&block)
        end

        def method_missing(m, *args, &block)
          resource = @recipe.send(m, *args, &block)

          if resource.is_a?(Chef::Resource)
            actions = Array(resource.action)
            resource.action(:nothing)

            actions.each do |action|
              resource.run_action(action)
            end
          end

          resource
        end
      end

      #
      # A top-level class for manipulation the resource collection.
      #
      class Injector
        def initialize(recipe, identifier, placement)
          @recipe              = recipe
          @resource_collection = @recipe.run_context.resource_collection
          @resource            = @resource_collection.lookup(identifier)
          @placement           = placement
        end

        def evaluate(&block)
          instance_eval(&block)
        end

        def insert_before(resource, new_resource)
          @resource_collection.instance_eval do
            # Remove the resource because it's automatically created
            @resources.delete_at(@resources_by_name[new_resource.to_s])
            @resources_by_name.delete(new_resource.to_s)

            index = @resources_by_name[resource.to_s]
            @resources.insert(index, new_resource)
            @resources_by_name[new_resource.to_s] = index
          end
        end

        def insert_after(resource, new_resource)
          @resource_collection.instance_eval do
            # Remove the resource because it's automatically created
            @resources.delete_at(@resources_by_name[new_resource.to_s])
            @resources_by_name.delete(new_resource.to_s)

            index = @resources_by_name[resource.to_s] + 2
            @resources.insert(index, new_resource)
            @resources_by_name[new_resource.to_s] = index
          end
        end

        def method_missing(m, *args, &block)
          new_resource = @recipe.send(m, *args, &block)

          case @placement
          when :before
            insert_before(@resource, new_resource)
          when :after
            insert_after(@resource, new_resource)
          else
            super
          end
        end
      end
    end

    module DSL
      #
      # Dynamically run resources specified in the block during the compilation
      # phase, instead of the convergence phase.
      #
      # @example The old way
      #   package('apache2') do
      #     action :nothing
      #   end.run_action(:install)
      #
      # @example The new way
      #   at_compile_time do
      #     package('apache2')
      #   end
      #
      # @example Resource actions are run in order
      #   at_compile_time do
      #     service 'apache2' do
      #       action [:enable, :start] # run_action(:enable), run_action(:start)
      #     end
      #   end
      #
      def at_compile_time(&block)
        Chef::Sugar::Filters::AtCompileTime.new(self).evaluate(&block)
      end

      #
      # Dynamically insert resources before an existing resource in the
      # resource_collection.
      #
      # @example Write a custom template before the apache2 service actions
      #          are run
      #   before 'service[apache2]' do
      #     template '/etc/apache2/thing.conf' do
      #       source '...'
      #     end
      #   end
      #
      #
      # @param [String] identifier
      #   the +resource[name]+ identifier string
      #
      def before(identifier, &block)
        Chef::Sugar::Filters::Injector.new(self, identifier, :before).evaluate(&block)
      end

      #
      # Dynamically insert resources after an existing resource in the
      # resource_collection.
      #
      # @example Write a custom template after the apache2 service actions
      #          are run
      #   after 'service[apache2]' do
      #     template '/etc/apache2/thing.conf' do
      #       source '...'
      #     end
      #   end
      #
      #
      # @param [String] identifier
      #   the +resource[name]+ identifier string
      #
      def after(identifier, &block)
        Chef::Sugar::Filters::Injector.new(self, identifier, :after).evaluate(&block)
      end
    end

    module RecipeDSL
      #
      # @deprecated The description is in the method body pretty accurately...
      #
      def compile_time(&block)
        message = <<-EOH

The Chef Sugar recipe DSL method `compile_time' has been renamed to
`at_compile_time'! This is a breaking change that was released in a patch
version, so please continue reading to understand the necessary semantic
versioning violation.

Chef Software implemented a version of `compile_time' in Chef 12.1, breaking any 
cookbook that uses or depends on Chef Sugar on Chef 12.1:

    https://www.chef.io/blog/2015/03/03/chef-12-1-0-released

In order to progress Chef Sugar forward, the DSL method has been renamed to
avoid the namespace collision.

In short, you should change this:

    compile_time do
      # ...
    end

to this:

    at_compile_time do
      # ...
    end

EOH

        if Chef::Resource::ChefGem.instance_methods(false).include?(:compile_time)
          message << <<-EOH
You are running a version of Chef Client that includes the `compile_time'
attribute on core Chef resources (most likely Chef 12.1+). Instead of continuing
and having Chef provide you with an obscure error message, I am going to error
here. There is no way for the Chef Recipe to successfully continue unless you
change the Chef Sugar `compile_time' method to `at_compile_time' in your Chef
recipes.

You should NOT change resource-level `compile_time' attributes:

    package "foo" do
      compile_time true # Do NOT change these
    end

I truly apologize for the inconvienence and hope the reason for introducing this
breaking change is clear. I am sorry if it causes extra work, but I promise this
error message is much more informative than "wrong number of arguments".

If you have any questions, please feel free to open an issue on GitHub at:

    https://github.com/sethvargo/chef-sugar

Thank you, and have a great day!
EOH
          raise RuntimeError, message
        else
          message << <<-EOH
You are running a version of Chef Client that does not include the
`compile_time' attribute on core Chef resources (most likely less than
Chef 12.1), so this is just a warning. Please consider changing the Chef Sugar
`compile_time' method to `at_compile_time' in your Chef recipes. If you upgrade
Chef, your recipes WILL break.
EOH
          Chef::Log.warn(message)
          at_compile_time(&block)
        end
      end
    end
  end
end
