# Source

This is the only local `@conceptadev/docs-theme` package in Ack.
It tracks the public API and source corrections in Concepta docs-theme PR #2,
source revision `117abf35b821603fa63869db2d45f365284ef1ee`.

The package manifest uses source exports because Next.js transpiles this local
workspace package. Its explicit Base UI development dependency prevents a
second Radix-based UI implementation from being installed for the peer.
The separate `status` export is safe for Node-based MDX configuration evaluation;
it does not load React components or extensionless UI modules.

The shared package remains private and unpublished. Once a reviewed release is
available, replace `workspace:*` with its version, regenerate the lockfile,
remove this directory, and rerun the root/subpath build and browser checks.
Do not edit this snapshot independently without bringing the shared source
change back to the theme repository.
