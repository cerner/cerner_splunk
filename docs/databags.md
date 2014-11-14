Data Bags
=========
Here we'll describe the various types of hashes that come out of [data bag items](http://docs.opscode.com/essentials_data_bags.html) used with `cerner_splunk` cookbook, and their formats.

It is recommended that all of these items live in an `cerner_splunk` data bag, but they are configurable through [attributes](attributes.md) and keys on other Hashes.

Hashes and other values stored in data bag items are referenced by strings that take the form "data_bag/data_bag_item:key" which would reference the key, inside a particular data_bag_item inside a particular data bag. Similarily, An entire data bag item could be referenced by a string matching "data_bag/data_bag_item"

Contextual Hashes
-----------------
If a hash is marked as being contextual, after resolving the overall hash by the coordinate given, we then attempt to resolve a hash out of that hash, by looking for keys matching (in order) the splunk node name e.g. `node[:splunk][:config][:host]`, the Chef node name, the node fully qualified domain name, the splunk node type, and the empty string. Each of these context keys can be missing (in which case resolution will attempt the next one in the list, or return nil if no more contexts exist to try), or can terminate with a hash, a String aliasing that particular context to another context, or null (meaning explicitly unconfigured). The code behind this is in the recipe.rb library in CernerSplunk.keys (to get the context resolution order) and in the databags.rb library, CernerSplunk::DataBag.load with the pick_context option to perform the resolution.

Cluster Hash
------------
The Cluster Hash is part of a plaintext data bag item that defines a logical group of Splunk Servers (Often a single master and multiple slave VMs). It is created and owned by the splunk cluster administrator, and is referenced by others who want to point forwarders or search heads to the cluster.

* `['license_uri']` - SplunkAPI URI of the License Server (Required for getting onto the Enterprise license, if unset, use trial license)
* `['master_uri']` - SplunkAPI URI of the cluster master (Required for servers connecting to managed clusters)
* `['settings']` -  Hash of Cluster settings (Required for servers connecting to managed clusters),
* `['settings'][???]` - Valid values are those under the clustering stanza of [server.conf][]
* `['replication_ports']` - Configuration for cluster slave replication ports (required for cluster slaves)
* `['replication_ports']['###']` - Port number to listen on
* `['replication_ports']['###']['_cerner_splunk_ssl']` - boolean if the port is ssl enabled (false)
* `['replication_ports']['###']['???']` - Other replication-port stanza properties from [server.conf][]
* `['receivers']` - Array of strings of hosts where this cluster's indexers are listening. (Required for forwarders)
* `['receiver_settings']['splunktcp']['port']` - Port indexers are listening on, and forwarders are sending data (required for forwarders and receivers)
* `['indexes']` - A String pointing to an indexes data bag hash. (Coordinate form as described above)
* `['apps']` - A String pointing to an apps data bag hash. (Coordinate form as described above)

License Hash
------------
The License Hash is part of a data bag item encrypted with [Chef Vault](https://github.com/Nordstrom/chef-vault) to hold the license data.

* `[A Decriptive File-Name]` - Corresponding License (XML) contents. (There can be many of these) Remember to change newlines to `\n` to conform to proper JSON format.

Indexes Hash
------------
An Indexes Hash is part of a plaintext data bag item that defines the set of indexes defined in a cluster. It is separate from the Cluster data bag primarily for size concerns.

* `['config']` - These define the [indexes.conf] stanzas (in fairly raw form).
* `['flags']` - These define boolean processing flags per index. All flags are default 'false' but can be set to true. Current flags include:
    * `noGeneratePaths` - Do not generate the homePath,coldPath,thawedPath to this index when not present in the config above
    * `noRepFactor` - Do not add 'repFactor = auto' to this index when not present in the config on a cluster master.
* `['metadata']` - These define ownership / other reference metadata around indexes and their owners (ALPHA!!! CAN CHANGE!!!)

Roles Hash
----------
A Roles Hash is a contextual (see above) Hash, part of a plaintext data bag item that defines roles for every node in a cluster, and is pointed to by the `node[:splunk][:config][:roles]` attribute (usually set in your environment).

* `[context]` - Final Hash, String Alias, or force unconfigured (null)
* `[context]['default']` - defines the base settings for all roles
* `[context][role_name]` - defines the settings for a particular role
* `[context][role_name]['app']` - Default app for the role ('default_namespace' in [user-prefs.conf][])
* `[context][role_name]['tz']` - Default timezone for the role ('tz' in [user-prefs.conf][])
* `[context][role_name]['showWhatsNew']` - 0 to supress the "what's new in Splunk 6 popup" ('showWhatsNew in [user-prefs.conf][])
* `[context][role_name]['capabilities']` - An array of capability names to enable for this role or when prefixed with an '!' to explicitly disable (which is only useful when applied to those roles that ship with Splunk/other apps in default configurations) in [authorize.conf][].
* `[context][role_name][something_else]` - A string, or array for something else defined in [authorize.conf][]. Arrays are automatically turned into semi-colon delimited lists.

Authentication Hash
-------------------
An Authentication Hash is a contextual (see above) Hash, part of a plaintext data bag item that is used to configure how users authenticate to the system per [authentication.conf][].

* `['authType']` - Matches the key of the same name in the authentication stanza. One of Splunk, LDAP, Scripted, but we'll attempt to guess it based on the other configured keys
* `['passwordHashAlgorithm']` - Only valid for 'Splunk' authType. See key of the same name in the authentication stanza
* `['scriptPath']` - Only valid for the 'Scripted' authType, see key in the authSettings
* `['scriptSearchFilters']` - Only valid for the 'Scripted' authType, see key of the same name in authentication settings.
* `['cacheTiming']` - Only valid for the 'Scripted' authType, Hash configuring stanza of the same name.
* `['LDAP_strategies']` - An LDAP Hash, A string pointing to an LDAP Hash, or an Array of Strings and Hashes.
* `['LDAP_strategies']['bag']` - If an LDAP_Strategies item is a hash, this points to the LDAP Hash of defaults, that can have portions overriden by the rest of the local hash.

LDAP Hash
---------
An LDAP Hash is part of a plaintext data bag item that configures connection information to LDAP. It can be referenced from or defined as part of 'LDAP_strategies'

* `['strategy_name']` - What to call the strategy. By default this is derived from a combination of the host/port.
* `['roleMap']` - Hash mapping Splunk roles to 1 to many LDAP roles
* `['roleMap'][splunk_role]` - String or Array of Strings of LDAP roles to map the given splunk role to
* `['bindDNpassword']` - Coordinate String (see above), pointing to a String within a Chef Vault encrypted data bag item.
* `[other]` - Other keys under an LDAP <authSettings-key> stanza as documented in [authentication.conf][].

Alerts Hash
-----------
An Alerts hash is a contextual (see above) Hash, part of a plaintext data bag item that configures [alert-actions.conf][]

* `['bag']` - A string that points to an externalized Alerts Hash in which all keys (except this one) are valid
* `['email']['auth_password']` - Coordinate String (see above), pointing to a String within a Chef Vault encrypted data bag item.
* `[stanza][key]` - Any other stanza/key combination from [alert-actions.conf][]

Apps Hash
-----------
An apps hash is a contextual (see above) Hash, part of a plaintext data bag item or specified directly as attributes that configures apps. A special key of 'master-apps' is looked for managing apps that should be installed and pushed by the cluster master, instead of locally.

* `['bag']` - A string that points to an externalized Apps Hash in which all keys (except this one) are valid. 
* `[app]` - The name of an app to manage (disk name)
* `[app]['remove']` - If true, remove this app instead of creating / managing  (default - false)
* `[app]['local']` - If true, manage files in the local directories instead of the "default" (default-false)
* `[app]['files']` - Hash of files to manage under the "default" or "local" directory.
* `[app]['files'][filename]` - Contents of a particular file to manage. It can take 3 values, a hash of stanzas -> key-value pairs (then written with the splunk template), a string (written as is), or nil / false (deleted). If the hash or string is empty, the file is also deleted.
* `[app]['permissions']` - Hash of permissions to manage for the app.
* `[app]['permissions'][object]` - Permissions to manage for a particular knowledge object or class of knowledge objects
* `[app]['permissions'][object]['access']['read']` - array of roles or String '*' allowed to read the object
* `[app]['permissions'][object]['access']['write']` - array of roles or String '*' allowed to write the object
* `[app]['permissions'][object][???]` - Any other stanza from [default.meta][]


Docs Navigation
===============
* [Docs Readme](README.md)
* [Repository Readme](../README.md)

[server.conf]: http://docs.splunk.com/Documentation/Splunk/latest/Admin/Serverconf
[indexes.conf]: http://docs.splunk.com/Documentation/Splunk/latest/Admin/Indexesconf
[user-prefs.conf]: http://docs.splunk.com/Documentation/Splunk/latest/Admin/User-prefsconf
[authorize.conf]: http://docs.splunk.com/Documentation/Splunk/latest/Admin/Authorizeconf
[authentication.conf]: http://docs.splunk.com/Documentation/Splunk/latest/Admin/Authenticationconf
[alert-actions.conf]: http://docs.splunk.com/Documentation/Splunk/latest/Admin/Alert-actionsconf
[default.meta]: http://docs.splunk.com/Documentation/Splunk/latest/Admin/Defaultmetaconf
