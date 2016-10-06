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

Docs Navigation
===============
* [Docs Readme](README.md)
* [Repository Readme](../README.md)
