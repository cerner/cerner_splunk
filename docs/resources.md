Resources
=========
These are Resources / Providers / Definitions supplied by the Cerner Splunk cookbook

`cerner_splunk_forwarder_monitors`
----------------------------------
The purpose of this resource is to setup inputs from a recipe and notify the splunk service to restart upon changes. It is equivalent to the monitors LWRP in the splunk_forwarder cookbook.

### Actions

| Action     | Description
| :--------  | :----------
| `:install` | Default. Use to setup/reconfigure the listed inputs in the named app.
| `:delete`  | Removes the named app / and inputs.

### Attributes

| Attribute     | Description
| :-----------  | :----------
| `app`         | This is the name of the grouping of inputs (i.e. Splunk app) to configure. It defaults to the name of the resource.
| `index`       | The index to write the configured inputs to by default. Defaults to the value of node[:splunk][:main_project_index]
| `monitors`    | An array of inputs to configure (similar to how you'd configure node[:splunk][:monitors])

### Examples

Monitor a set of files, and send the data to the index set in `node[:splunk][:main_project_index]`

```ruby
cerner_splunk_forwarder_monitors 'foo' do
  monitors  [{
    path: '/logs/ice/*.log',
    sourcetype: 'my_cool_sourcetype'
  },{
    path: '/logs/access.log',
    sourcetype: 'access_combined'
  }]
end
```

Monitor some more files, and send the data to other indexes.

```ruby
cerner_splunk_forwarder_monitors 'bar' do
  index 'pop_health'
  monitors  [{
    path: '/logs/ice/*.log',
    sourcetype: 'my_cool_sourcetype'
    index: 'deep_freeze'
  },{
    path: '/logs/access.log',
    sourcetype: 'access_combined'
  }]
end
```

Remove a previously configured set of monitors.

```ruby
cerner_splunk_forwarder_monitors 'bar' do
  action :delete
end
```

`splunk_template`
-----------------
The purpose of this resource is to manage local configuration files in Splunk. It is an extension of the [`template`](http://docs.opscode.com/resource_template.html) resource, (and uses the template provider) but defaults things into splunk home of the splunk installation, uses a generic template, sets owner and permissions. You need to make sure that the appropriate installation recipe is run first (as it defaults the path based on the Splunk home). Everything is the same as the template resource except these additions/modifications

### Attributes

| Attribute     | Description
| :-----------  | :----------
| `stanzas`     | Hash of stanzas key to Hashes of key value pairs to send to the template, or a Block to generate the same hash at Convergence time instead of Compile time.
| `fail_unknown`| `true` (default) to fail the chef run if the config_file is not known. `false` to only log a warning in this case.
| `variables`   | If left unset, will return a hash of `:stanzas` mapped to the evaluation of stanzas above. Could be overridden if you so chose, but the `stanzas` attribute will be ignored.
| `path`        | Path to the file to manage (within the splunk home directory). Like the template resource, this will be taken from the name of the resource by default. However you can also write to the local files of the system / an app easily by specifying `system/file.conf` `apps/app-name/file.conf` or even `master-apps/app-name/file.conf` as the resource name.

### Defaulted Attributes from template resource

| Attribute     | Default
| :-----------  | :----------
| `backup`      | `false`
| `cookbook`    | `cerner_splunk`
| `source`      | `generic.conf.erb`
| `user`        | node[:splunk][:user]
| `group`       | node[:splunk][:group]
| `mode`        | '0600'
| `variables`   | `nil`

Templates
=========

`cerner_splunk::generic.conf.erb`
------------------------------
This is the default template for the `splunk_template` Resource. It takes a Hash of Hashes (stanzas) and fills out a configuration file that is the same pattern of the majority of Splunk config files.

Docs Navigation
===============
* [Docs Readme](README.md)
* [Repository Readme](../README.md)
