# Automated Release Management

## Overview

The `release-engine-core` repository uses an automated CI/CD pipeline to manage releases via GitHub Actions. This workflow automatically creates versioned releases when pull requests are merged into the `main` branch.

## How It Works

### Trigger

The workflow triggers automatically when a pull request is **merged** (not just closed) into the `main` branch.

### Version Determination

The workflow uses **semantic versioning** (MAJOR.MINOR.PATCH) and determines the version bump based on labels applied to the pull request:

- **`major` label**: Increments the major version (e.g., v1.2.3 → v2.0.0)
  - Use for breaking changes or major new features
- **`minor` label**: Increments the minor version (e.g., v1.2.3 → v1.3.0)
  - Use for new features that are backward-compatible
- **`patch` label**: Increments the patch version (e.g., v1.2.3 → v1.2.4)
  - Use for bug fixes and small improvements
- **No label**: Defaults to patch version increment

### Release Creation

When a PR is merged, the workflow:

1. **Fetches the latest tag** from the repository
   - If no tags exist, starts from v0.0.0
2. **Determines version bump** based on PR labels
3. **Calculates the new version** using semantic versioning
4. **Creates and pushes a new tag** to the repository
5. **Creates a GitHub release** with:
   - Release name: PR title
   - Release description: PR description + metadata
   - Tag: The newly created version tag

## Usage Guide

### For Pull Request Authors

1. **Add a version label** to your PR before merging:
   - Add `major`, `minor`, or `patch` label based on the nature of your changes
   - If you forget to add a label, the workflow will default to a `patch` bump

2. **Write clear PR titles and descriptions**:
   - The PR title becomes the release name
   - The PR description becomes the release notes
   - Follow these best practices:
     - Use clear, descriptive titles (e.g., "Add support for multi-region deployments")
     - Include detailed information in the description about what changed
     - List breaking changes (if any) prominently
     - Include migration steps for breaking changes

### For Maintainers

#### Available Labels

Ensure these labels exist in the repository:
- `major` - For major version bumps
- `minor` - For minor version bumps  
- `patch` - For patch version bumps

#### Permissions

The workflow requires the following permissions:
- `contents: write` - To create tags and releases
- `pull-requests: read` - To read PR metadata and labels

These are configured in the workflow file.

#### Manual Release Creation

If you need to create a release manually (e.g., for the first release or to fix an issue):

```bash
# Create and push a tag
git tag -a v1.0.0 -m "Release v1.0.0"
git push origin v1.0.0

# Then create a release via GitHub UI or CLI
gh release create v1.0.0 --title "Release v1.0.0" --notes "Release notes here"
```

#### Troubleshooting

**Issue**: Workflow doesn't trigger
- **Solution**: Ensure the PR was merged (not just closed) into `main`

**Issue**: Wrong version created
- **Solution**: Check that the correct label was applied to the PR before merging

**Issue**: Tag already exists
- **Solution**: Delete the tag locally and remotely, then re-trigger the workflow:
  ```bash
  git tag -d v1.2.3
  git push origin :refs/tags/v1.2.3
  ```

**Issue**: Permission denied when creating release
- **Solution**: Verify the `GITHUB_TOKEN` has appropriate permissions

## Workflow File

The workflow is defined in `.github/workflows/release.yml`.

## Examples

### Example 1: Bug Fix Release

1. Create a PR with bug fixes
2. Add the `patch` label
3. Merge the PR
4. Result: v1.2.3 → v1.2.4

### Example 2: New Feature Release

1. Create a PR with a new feature
2. Add the `minor` label
3. Merge the PR
4. Result: v1.2.4 → v1.3.0

### Example 3: Breaking Change Release

1. Create a PR with breaking changes
2. Add the `major` label
3. Include migration guide in PR description
4. Merge the PR
5. Result: v1.3.0 → v2.0.0

## Version History

You can view all releases and their associated tags in the [Releases](https://github.com/thecloudexplorers/release-engine-core/releases) page.

## Additional Resources

- [Semantic Versioning Specification](https://semver.org/)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Creating Releases Documentation](https://docs.github.com/en/repositories/releasing-projects-on-github/managing-releases-in-a-repository)
