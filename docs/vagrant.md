Running with Vagrant
====================
* The first vagrant box is for running chef zero. Provisioning it will upload all of the contents of the `vagrant_repo` directory, plus the cookbook and all dependencies using Berkshelf.
* The other vagrant boxes all require the chef machine to be running, and setup Splunk running machines of various kinds, names being prefixed according to groupings, to enable using regular expressions to specify vagrant operations on subsets of machines. (See [Vagrant's documentation on controlling multiple machines](http://docs.vagrantup.com/v2/multi-machine/))
* With the chef vm running, chef contents can be reloaded easily
  * `vagrant provision chef` - will restart the chef-zero server as well as reloading everything (clearing all state)
  * `KNIFE_ONLY=1 vagrant provision chef` - will only update cookbooks and the chef-repo data. (maintaining state)
* The chef vm also packages splunk apps from vagrant_repo/apps for consumption by the other vagrant machines over port 5000
  * `vagrant provision chef` - Will only package splunk apps if they're not already packaged.
  * `REGEN_APPS=1 vagrant provision chef` - Will repackage all apps.
* You can speed up repeated provisioning attempts by mirroring the Splunk package downloads locally:
  1. Download the needed splunk packages locally, in a directory structure mirroring that of download.splunk.com
    * You can find URLs for Splunk packages at the [Splunk download page](http://splunk.com/download)
  * Host the root of your mirrored structure on port 8080 using a lightweight HTTP server such as the node package [http-server](https://npmjs.org/package/http-server)
  * Un-comment the `splunk-mirrors` role in the Vagrant file. (Do not check in this modification of your Vagrantfile)
* `vagrant-omnibus` installer currently requires internet access to function.

**Note**:
If you want to set up the vagrant cluster to use the license pools defined in the [license pool hash](databags.md#license-pool-hash) databag, add the `configure_guids` recipe to the run_list on the cluster slave (to update the GUIDs on these slaves to predefined values) and update the `license_uri` attribute in the cluster-vagrant databag item to point to the cluster master (_https://33.33.33.30:8089_).
After you spin up the cluster slaves you will have to restart the cluster master to bring the cluster to a stable state. While spinning up the cluster slaves, they are re-assigned with different GUIDS by the `configure_guids` recipe which requires a restart (this restart can take a while to complete). Cluster master is restarted so that it can identify the new GUIDS.

# Spinning up a Search Head Cluster in Vagrant

`vagrant up /c2_.*/`

c2_boot1 and c2_boot2 are the bootstrap nodes and are provisioned first. c2_captain is then provisioned and the cluster is established. c2_deployer is provisioned and pushes apps to the cluster. Finally c2_newnode is provisioned and joins the cluster as a scale up example.

# Spinning up Multisite Cluster in Vagrant

<code>vagrant up /s1_.\*/ /s2_.\*/</code>

Docs Navigation
===============
* [Docs Readme](README.md)
* [Repository Readme](../README.md)
