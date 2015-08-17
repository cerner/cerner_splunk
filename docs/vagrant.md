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
    * You can find the suffixes of files at the [Splunk download page](http://splunk.com/download)
    * Copy a download link, it will look like `http://www.splunk.com/page/download_track?file=6.0.1/splunk/linux/splunk-6.0.1-189883-linux-2.6-x86_64.rpm&platform=...`
    * The `file` query parameter will be the suffix you add onto `http://download.splunk.com/releases/`
      * In this example the full url is: `http://download.splunk.com/releases/6.0.1/splunk/linux/splunk-6.0.1-189883-linux-2.6-x86_64.rpm`
      * You will download the file locally to `<Mirror root>/releases/6.0.1/splunk/linux/splunk-6.0.1-189883-linux-2.6-x86_64.rpm
  * Host the root of your mirrored structure on port 8080 using a lightweight HTTP server such as the node package [http-server](https://npmjs.org/package/http-server)
  * Un-comment the `splunk-mirrors` role in the Vagrant file. (Do not check in this modification of your Vagrantfile)
  * Required files and sizes (assuming current cookbook versions and running the aeon-forwarder test as well)
    * `splunk-6.0.1-189883-linux-2.6-x86_64.rpm` and `splunk-6.0.1-189883-linux-2.6-amd64.deb` ~ 75MB each
    * `splunkforwarder-6.0.1-189883-linux-2.6-x86_64.rpm` and `splunkforwarder-6.0.1-189883-linux-2.6-amd64.deb` ~ 11MB each
    * `splunkforwarder-4.3-115073-Linux-x86_64.tgz` ~ 18MB
* `vagrant-omnibus` installer currently requires internet access to function.

Docs Navigation
===============
* [Docs Readme](README.md)
* [Repository Readme](../README.md)
