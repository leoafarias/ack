# Source

This is the only local `@conceptadev/docs-theme` package in Ack.
It tracks the public API and source corrections in Concepta docs-theme PR #2,
source revision `49766e3627c0c21f9b045f80855e4198c9d859ec`.

The package manifest uses source exports because Next.js transpiles this local
workspace package. Its explicit Base UI development dependency prevents a
second Radix-based UI implementation from being installed for the peer.

The shared package remains private and unpublished. Once a reviewed release is
available, replace `workspace:*` with its version, regenerate the lockfile,
remove this directory, and rerun the root/subpath build and browser checks.
Do not edit this snapshot independently without bringing the shared source
change back to the theme repository.
