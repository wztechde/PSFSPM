# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.2.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

- TBD

## [0.1.0] - 2012-12-12

- Initial release.
  In this version I set the foundation for further releases.
  I set some objects to better organize the permission tasks.
  I also created some functions to create those objects
  - New-FMPermission creates a permission object
  - New-FMPathPermission creates a path permission object -> path with several permissions
  - New-FMDirectory creates a directory permission object -> a bunch of path permission with a root/child
    dependency to hold a complete folder structure (future use)
- Function Get-ChilditemEnhanced is a proxy function, that adds the parameter -Startdepth to set a minimum
  depth of items to return
- Function 'Set-Permission' runs with explicit identities or objects defined (help set-permission for details)
