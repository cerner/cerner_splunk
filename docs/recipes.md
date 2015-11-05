Recipes
=======
These are all of the public facing recipes, and brief descriptions of what they do. Only one Installation recipe can be on your runlist at a time (since the Splunk UF and the full Splunk instance can both perform the same tasks of consuming data to be sent along).

Forwarder Installation Recipes
------------------------------
The forwarder installation recipes will clean up an existing forwarder if migrating from one type to another. Migrations to a Universal Forwarder should happen cleanly, however migrations away from a Universal Forwarder to another type will likely result in duplicates of past log entires being forwarded. You may wish to remove old log files first or clean up duplicates in the Splunk instance it is forwarding to.

### `cerner_splunk` / `cerner_splunk::forwarder`

Installs the Splunk Universal Forwarder on your system. Most people will only want this recipe (hence why it's the default recipe)

### `cerner_splunk::heavy_forwarder`

Installs and configures Splunk Server as a heavy forwarder. Forwards logs.

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
