# Publishing Guide

This document explains how to version and publish the Ack packages to pub.dev.

## Overview

The Ack project uses GitHub Releases to manage versioning and publishing. This approach provides:

- Centralized release management through GitHub's UI
- Explicit version/changelog control in this repository
- Automated publishing to pub.dev

## Release Process

### 1. Prepare for Release

Before creating a release:

1. Ensure all changes are committed and pushed to the `main` branch
2. Verify that all tests pass by running `dart run melos run test` (include `dart run melos run validate-jsonschema` and `dart run melos run test:gen` for full coverage)
3. Confirm that the `Release preflight` workflow is green on the merge commit. Run its checks locally with:

   ```bash
   dart scripts/stage_min_sdk_workspace.dart /tmp/ack-min-dart
   dart scripts/stage_package.dart ack_firebase_ai /tmp/ack-min-flutter --local-deps
   dart run melos run validate-jsonschema:batch
   dart scripts/api_check.dart 1.1.0
   dart run melos run build && git diff --exit-code
   dart scripts/publish_dry_run.dart
   ```

4. Check that the documentation is up to date across the repo and docs site
5. Decide on the new version number following [Semantic Versioning](https://semver.org/) and apply it consistently to every publishable package (`ack`, `ack_annotations`, `ack_generator`, `ack_firebase_ai`, `ack_json_schema_builder`, `ack_mcp_dart`)
6. Ensure package CHANGELOG entries are finalized before tagging. If you want a link-only entry for a version, you can run `dart scripts/update_release_changelog.dart <version> [tag]` after `dart run melos version`.

### 2. Create a GitHub Release

1. Go to the [Releases page](https://github.com/conceptadev/ack/releases) in the repository
2. Click "Draft a new release"
3. Create a new tag in the format `v0.2.0` (must start with "v")
4. Add a title, e.g., "Release v0.2.0"
5. Add detailed release notes with a structure like:

```markdown
# Release v0.2.0

This release introduces [brief description of major changes].

## Key Features
- **Feature 1**: Description
- **Feature 2**: Description

## Breaking Changes
- **Feature**: Description of breaking change
  - Detail 1
  - Detail 2

## Improvements
- **Feature**: Description of improvement
  - Detail 1
  - Detail 2

## Bug Fixes
- Fixed [description of bug]
```

> **Note**: You should manually update the `pubspec.yaml` and `CHANGELOG.md` files in each package before creating a tag/release. The release workflow publishes what is already committed.

6. Choose whether this is a pre-release:
   - Check "This is a pre-release" if you're releasing a beta or RC version
   - Pre-releases WILL be published to pub.dev as pre-release versions
   - Only draft releases won't be published to pub.dev

7. Click "Publish release"

### 3. Automated Steps

When the `v*` tag is pushed, the GitHub Actions workflow will automatically:

1. Verify the tag with `dart scripts/verify_release_tag.dart`. The tag commit
   must be reachable from `main`, and the tagged version must match every
   publishable `pubspec.yaml` version and every `CHANGELOG.md` heading.
2. Rerun `.github/workflows/preflight.yml` on the tagged commit.
3. Test and publish the independent `ack` and `ack_annotations` foundation
   packages.
4. After both hosted versions are available, test and publish `ack_generator`.
5. After the generator stage completes, test and publish
   `ack_json_schema_builder`, `ack_mcp_dart`, and `ack_firebase_ai`.
6. Run `dart scripts/publish_dry_run.dart` immediately before each package
   upload and require zero warnings.

Each publish stage first copies its package out of the workspace with
`dart scripts/stage_package.dart`, then resolves and tests it there. Workspace
resolution replaces every `ack: ^1.2.0` constraint with the local sibling
directory, so only the staged copy proves that a pub.dev consumer can resolve
the release. The stages are deliberately sequential, so each dependent package
resolves the foundation version that the preceding stage published.

Every external action is pinned to a commit SHA, and the Flutter SDK is
installed only through `.github/actions/setup-flutter`, which verifies the
archive against the SHA-256 value in `.github/flutter-releases.json`.
`test/scripts/release_workflow_security_test.dart` enforces these rules.

### pub.dev automated publishing

The publish job grants `id-token: write`, then the pinned
`dart-lang/setup-dart` action exchanges GitHub's OIDC token for a short-lived
pub.dev `PUB_TOKEN` and registers it with `pub`. Each of the five packages must
also enable automated publishing on pub.dev before the first automated release:

1. Open `https://pub.dev/packages/<package>/admin`.
2. Enable **Automated publishing** from GitHub Actions.
3. Set the repository to `conceptadev/ack`.
4. Set the tag pattern to `v{{version}}`.
5. Set the environment to `Production`, which matches the publish job.

Confirm all five packages after any repository rename or owner change,
because pub.dev stores the repository name, not its numeric id.

The workflow does **not** modify versions or changelogs, and does **not** commit changes back to the repository.

### 4. Verify the Release

After the workflow completes:

1. Check that the packages are available on pub.dev
2. Verify that the version numbers and changelogs are correct
3. Test the published packages in a new project to ensure they work as expected

## Alternative: Manual Versioning

If needed, you can version packages locally from conventional commits:

```bash
# Propose/apply version and changelog updates
dart run melos version

# Non-interactive
dart run melos version --yes

# Push the changes and tags
git push --follow-tags
```

## Manual Publishing

Publishing runs only from a `v*` tag. The repository has no `melos run publish`
or `melos run release` script, because a one-command publish would skip tag
verification, the preflight, the `Production` environment gate, and the staged
hosted-dependency proof.

Publish by hand only when GitHub Actions is unavailable. Run every gate first,
from a clean checkout of the tag:

```bash
dart scripts/verify_release_tag.dart v<version>
dart scripts/publish_dry_run.dart
dart run melos run validate-jsonschema:batch
dart scripts/api_check.dart <previous-version>

# Only then, one package at a time, in release order:
#   ack, ack_annotations -> ack_generator -> ack_json_schema_builder, ack_mcp_dart, ack_firebase_ai
(cd packages/<package> && dart pub publish)
```

A manual upload uses your personal pub.dev credentials rather than the
repository's OIDC identity. Prefer fixing the workflow.

## Troubleshooting

### Release Workflow Fails

If the release workflow fails, check:

1. **Test Failures**: Fix any failing tests or analyze issues
2. **Version Issues**: Check if the version is valid and follows semantic versioning
3. **Permission Issues**: Ensure the GitHub Actions workflow has the necessary permissions
4. **Git Issues**: There might be problems with pushing commits back to the repository

### Manual Publishing Issues

If manual publishing fails:

1. **Authentication**: Run `dart pub publish` and follow its authentication
   prompt. If your release process explicitly uses a pub.dev token instead of
   browser authorization, add that token with
   `dart pub token add https://pub.dev`.
2. **Version Conflicts**: Check if the version already exists on pub.dev
3. **Dependency Issues**: Verify that all dependencies are correctly specified

## Version Numbering

The Ack project follows [Semantic Versioning](https://semver.org/):

- **Major version (x.0.0)**: Incompatible API changes
- **Minor version (0.x.0)**: Backwards-compatible functionality additions
- **Patch version (0.0.x)**: Backwards-compatible bug fixes

For pre-releases, use formats like `0.2.0-beta.1` or `0.2.0-rc.1`.

New packages have no API at an older release baseline. Record their first release
in `ackPackageFirstReleases` in `scripts/src/workspace_packages.dart`; API checks
skip only baselines before that version and compare normally from that version
onward. `ack_mcp_dart` starts at 1.2.0.
