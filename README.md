`cerner_splunk` Cookbook
===================
Installs and Configures Splunk forwarders and servers, and other components related to the same.

Based on the work done by [BBY Solutions](https://github.com/bestbuycom/splunk_cookbook) and a previous Cerner team.

[![Github Version](https://badge.fury.io/gh/cerner%2Fcerner_splunk.svg)](http://badge.fury.io/gh/cerner%2Fcerner_splunk)
[![Code Climate](https://codeclimate.com/github/cerner/cerner_splunk/badges/gpa.svg)](https://codeclimate.com/github/cerner/cerner_splunk)

Requirements
------------
* Red Hat Enterprise / CentOS 5.5+ / Windows Server 2008+ (forwarder only) or Ubuntu LTS 12.04+
* Chef 12+

Getting your logs into Splunk
-----------------------------
1. Configure which Splunk environment(s) should be collecting your logs
    * The Splunk Administrator of each environment will be able provide a Data Bag name and (plaintext) Data Bag item for the cluster configuration of Splunk
        * More than likely, the Data bag name will be 'cerner_splunk', and the Data bag item id will vary.
        * If you are on Enterprise Chef, this should already exist on the Chef server.
        * If you are on Open Source Chef, ask for the Chef repository(ies) and upload the data bags to your server on a regular basis.
    * For each name pair, build an id as a string in the form: `"#{data_bag}/#{data_bag_item}"`
    * Set the `node.default[:splunk][:config][:clusters]` attribute as an array of the ids collected above.
        * It is recommended that you set this in your nodes' [Environment](http://docs.opscode.com/essentials_environments.html), that way your roles for configuring monitors (Step 4) are then portable.
        * Splunk administrators will also have Chef Roles that can be included in a similar manner as was with Splunk 4, but this is a known anti-pattern, and we recommend getting away from it when you can.
        * You could also maintain the portable role, and have both the cluster role and the portable role on each of your nodes' run lists (which would be required if you cannot modify the environment, or need to override the environment).
2. Identify the name of the Splunk index(es) to which you will send your logs
    * If you do not know which index, work with your team, and the Splunk Administrators to identify an existing index or setup a new one.
3. Identify the log files you want Splunk to collect.
    * The Splunk process runs as the `splunk` user and group id, you will need to ensure that the logs are readable by this user.
        * If it helps, you can add the `splunk` user to a group, by adding the group name to an array attribute `node.default[:splunk][:groups]`
            * At a minimum, the group must be created in a resource in a recipe on the run_list prior to the cerner_splunk cookbook in order to have any effect. However If a requested group does not exist on the node by this point, this will NOT fail the chef run, but instead no action will occur.
    * It is highly recommended that you identify individual files instead of directories, and use some form of log rotation to manage space use.
    * Identify the format of the file, and identify a corresponding sourcetype for each.
        * Splunk has a number of [pretrained sourcetypes](http://docs.splunk.com/Documentation/Splunk/6.0.1/Data/Listofpretrainedsourcetypes) which should be preferred over custom sourcetypes if applicable.
        * The [Splunk Community](docs/contributing.md) may have additional sourcetypes that can be leveraged prior to building a custom sourcetype as well.
4. Create / add a role to configure Splunk for your system.
    * The role needs to have `'recipe[cerner_splunk]'` or `'recipe[cerner_splunk::heavy_forwarder]'` on the run_list
    * In your role, set `node.default[:splunk][:main_project_index]` to the index you are sending your logs (from step 2)
    * Set `node.default[:splunk][:monitors]` to the files with sourcetypes you want to monitor.
5. Upload and run!
    * You'll need to upload your role(s) & environments to the Chef server
    * You'll need to ensure that your nodes are in the correct envrionment
    * You'll need to ensure that the role(s) are on the nodes runlists
    * As root on each node, run chef-client & profit.

### Example Time!!!!
Let's say I'm on the Awesome Team, and I am setting up an Apache server, and want to feed the access and error logs into Splunk.

1. I talk to my trusty Splunk administrator, who points me to the `cluster-corporate` item in the `cerner_splunk` databag.
2. I've talked to my team and Splunk Administrator to also learn that Awesome Team's events should be forwarded to the `awesome_team` index.
3. My Apache access log will be located on my nodes at /var/log/httpd/access_log, and the error log is at /var/log/httpd/error_log.
    * My application recipe creates and grants access to these logs to the 'apachelogs' group, and the directories leading to them are traversable by members of the same group.
    * I'm using standard logging, so my Access log is in NCSA Combined format (access_combined sourcetype), and my Error log is sourcetype apache_error.
4. I make changes to my chef artifacts:
    * I alter the environment for my nodes:
     ```ruby
     # coding: UTF-8

     name 'awesomeness_corporate'
     description 'Node Environment for the Awesome Team Servers in Corporate'
     default_attributes(splunk: { config: { clusters: ['cerner_splunk/cluster-corporate']}})
     ```
    * I create a role:
     ```ruby
      # coding: UTF-8

      name 'awesomeness_ops'
      description 'Awesome Operations Role'
      run_list 'recipe[cerner_splunk]'
      default_attributes(
        splunk: {
          groups: ['apachelogs']
          main_project_index: 'awesome_team',
          monitors: [{
            path: '/var/log/httpd/access_log',
            sourcetype: 'access_combined'
          },{
            path: '/var/log/httpd/error_log',
            sourcetype: 'apache_error'
          }]
        })
     ```
5. I upload my environment, my role, set my nodes in my runlist, and profit!

Possibly Asked Questions
------------------------
* Can I send different monitors to different indexes?
    * Yes! Instead of specifying a `node['main_project_index']` on each of the monitors you would specify `index: indexname`
* Can I forward to multiple splunk clusters from the same forwarder?
    * Yes, specify a list of multiple cluster data bags instead of just a single cluster data bag.
    * Some upgrades and other security reasons may necessitate this, but usually it shouldn't be done since it counts double against the license volume.
    * Currently it is only supported to forward to indexes of the same name on both instances.
* Can I configure forwarders within my recipes?
    * Yes, use the `cerner_splunk_forwarder_monitors` resource in a recipe on your run list after the cerner_splunk recipe.
* Do I have to specify an index?
    * At Cerner: Yes. We use indexes to define ownership and access to data. Data sent to the default index will be rejected.
    * In general: No. Without specifying an index, you wind up in the 'main' index.
* Can I use this cookbook to configure a Universal Forwarder for a host image?
    * Yes, add `recipe[cerner_splunk::image_prep]` to the end of your run list.
* What if I have a question that's not anwsered here?
    * Cerner Associates may be able to reference the [Splunk User Guide](https://wiki.ucern.com/display/OPSINFRA/Splunk+User+Guide)
    * Could also ask in IRC or the other Splunk communities [as listed here](docs/contributing.md)

Documentation
-------------
More in depth documentation including server configuration and data bag formats is located [in this repository](docs/README.md)

License & Authors
-----------------
- Author:: David Crowder (david.crowder@cerner.com)
- Author:: Charlie Huggard (charlie.huggard@cerner.com)

### Original Cerner Cookbook
- Author:: Preston Koprivica (preston.koprivica@cerner.com)
- Author:: Garry Polley (garry.polley@cerner.com)

### Best Buy Cookbook
- Author:: Andrew Painter (andrew.painter@bestbuy.com)
- Author:: Bryan Brandau (bryan.brandau@bestbuy.com)
- Author:: Aaron Peterson (aaron@opscode.com)

```text
Copyright 2017 Cerner Innovation, Inc.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```
