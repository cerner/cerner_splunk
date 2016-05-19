default_action :go

attribute :app,      kind_of: String, name_attribute: true, regex: [/^[A-Za-z0-9_-]/]
attribute :index,    kind_of: String, required: false
attribute :monitors, kind_of: Array, default: []
