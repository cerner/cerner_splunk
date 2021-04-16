module ChefCLI
  class Dist
    # This class is not fully implemented, depending on it is not recommended!

    # The full marketing name of the product
    PRODUCT = "Chef Workstation".freeze
    PRODUCT_PKG_HOME = "chef-workstation".freeze

    # the name of the chef-cli gem
    CLI_PRODUCT = "Chef CLI".freeze
    CLI_GEM = "chef-cli".freeze

    # the name of the overall infra product
    INFRA_PRODUCT = "Chef Infra".freeze

    # name of the Infra client product
    INFRA_CLIENT_PRODUCT = "Chef Infra Client".freeze

    # The client's alias (chef-client)
    INFRA_CLIENT_CLI = "chef-client".freeze

    # The client's gem
    INFRA_CLIENT_GEM = "chef".freeze

    INSPEC_PRODUCT = "Chef InSpec".freeze
    INSPEC_CLI = "inspec".freeze

    # The name of the server product
    SERVER_PRODUCT = "Chef Infra Server".freeze

    WORKFLOW = "Chef Workflow (Delivery)".freeze

    # The chef executable, as in `chef gem install` or `chef generate cookbook`
    EXEC = "chef".freeze

    # Chef-Zero's product name
    ZERO_PRODUCT = "Chef Infra Zero".freeze
  end
end
