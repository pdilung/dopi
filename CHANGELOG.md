# Change Log
All notable changes to DOPi will be documented in this file.

## [0.1.11] - 2015-06-17
### Added
- MCollective RPC command plugin
- File replace command plugin (replace a string in a file)

### Fixed
- Missing plugin documentation added

## [0.1.10] - 2015-06-10
### Added
- The custom plugin now automatically sets the environment variable DOP_NODE_FQDN

### Changed
- The standard log level for the dopi CLI is now INFO rather than WARNING

### Fixed
- Loggers from dop_common and hiera are now integrated into dopi logger and obey the log level
- The custom command plugin no longer adds an additional new line after each output log entry
- A bug where Hiera was not correctly initialized in certain situations was fixed
- The puppet agent plugin should now expect error code 2 (changes) as default
- Trace should now also show a stacktrace for unexpected validation Errors
- The initconfig command will now avoid duplicate entries
- Boolean false values from the config file correctly overwrite the default now