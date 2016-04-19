Recipes
=======
These are all of the public facing recipes, and brief descriptions of what they do. Only one Installation recipe can be on your runlist at a time (since the Splunk UF and the full Splunk instance can both perform the same tasks of consuming data to be sent along).

Forwarder Installation Recipes
------------------------------
### `cerner_splunk` / `cerner_splunk::forwarder`

Installs the Splunk Universal Forwarder on your system. Most people will only want this recipe (hence why it's the default recipe)

### `cerner_splunk::heavy_forwarder`

Installs the Enterprise Splunk artifact on your system to be configured as a heavy forwarder.

Server Installation Recipes
---------------------------
These are installations of Full Splunk. Unless you are a Splunk Administrator, these are not the droids you are looking for.

### `cerner_splunk::license_server`

Installs and configures Splunk Server as a license server. Indexes logs.

### `cerner_splunk::cluster_master`

Installs and configures Splunk Server as a cluster master. Forwards logs.

### `cerner_splunk::cluster_slave`

Installs and configures Splunk Server as a cluster slave (indexer). Recieves & Indexes logs.

### `cerner_splunk::search_head`

Installs and configures Splunk Server as a cluster search head. Forwards logs.

### `cerner_splunk::server`

Installs and configures Splunk Server as a standalone server. Recieves & Indexes logs.
