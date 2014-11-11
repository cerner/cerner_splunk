# coding: UTF-8

name 'splunk_monitors_windows'

description 'Set the monitors for splunk'

default_attributes(
  splunk: {
    main_project_index: 'opsinfra',
    monitors: [
      {
        type: 'WinEventLog',
        path: 'Application',
        index: 'opsinfra'
      },
      {
        type: 'WinEventLog',
        path: 'System',
        index: 'opsinfra'
      },
      {
        type: 'WinEventLog',
        path: 'Security',
        index: 'opsinfra'
      }
    ]
  }
)
