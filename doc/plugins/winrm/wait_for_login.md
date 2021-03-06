# DOPi Command Plugin: Wait for SSH login Command

This DOPi Plugin will try to connect to the node until a successful login
is possible or until a timeout is reached.

## Plugin Settings:

The winrm/wait_for_login command plugin is based on the
[winrm cmd plugin](doc/plugins/winrm/cmd.md) and the
[custom command plugin](doc/plugins/custom.md) and inherits all their
parameters.

It will however overwrite the **exec** parameter, so it is not possible to
set a custom command in this plugin.

You may want to set a high **plugin_timeout** here to make sure it waits
long enough for all the nodes to come up if you provision the nodes while
waiting.

### connect_timeout (optional)

`default: 0`

__*NOTE:*__ This is not implemented for the winrm version of this plugin right now

Amount of seconds to wait while connecting until giving up.

### interval (optional)

`default: 10`

Amount of seconds to wait between login attempts.

## Examples:

### Simple Example

    - name "Wait until we can successfully login to the node"
      nodes:
        - 'windows01.example.com'
      command:
        plugin: 'winrm/wait_for_login'
        plugin_timeout: 300


### Complete Example

    - name "Wait until we can successfully login to the node"
      nodes:
        - 'windows01.example.com'
      command:
        plugin: 'winrm/wait_for_login'
        plugin_timeout: 300
        connect_timeout: 5
        interval: 30
