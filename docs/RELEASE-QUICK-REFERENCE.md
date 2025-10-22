# Quick Reference: Automated Release Management

## For Contributors

### Adding Version Labels to PRs

Before merging your PR to `main`, add ONE of these labels:

- `major` - For breaking changes (1.0.0 → 2.0.0)
- `minor` - For new features (1.0.0 → 1.1.0)  
- `patch` - For bug fixes (1.0.0 → 1.0.1)
- `bug` - For bug fixes (1.0.0 → 1.0.1, same as patch)

**Note:** If no label is added, defaults to `minor`.

### Writing Good PR Descriptions

Your PR title and description will become the release notes:

✅ **Good PR Title**
```
Add support for multi-region deployments
```

✅ **Good PR Description**
```markdown
## Changes
- Added configuration for multi-region support
- Updated deployment scripts to handle regional failover
- Added validation for region-specific settings

## Breaking Changes
None

## Testing
- Tested deployment to 3 regions
- Verified failover scenarios
```

❌ **Avoid**
- Generic titles like "Update code" or "Fix bug"
- Empty descriptions
- Missing context about what changed

## For Maintainers

### Creating Labels

Ensure these labels exist in the repository:

```bash
gh label create major --description "Major version bump (breaking changes)" --color "d73a4a"
gh label create minor --description "Minor version bump (new features)" --color "0075ca"
gh label create patch --description "Patch version bump (bug fixes)" --color "cfd3d7"
gh label create bug --description "Bug fix (patch version bump)" --color "d73a4a"
```

### Manual Release (if needed)

```bash
# Create and push tag
git tag -a v1.0.0 -m "Release v1.0.0"
git push origin v1.0.0

# Create release via GitHub CLI
gh release create v1.0.0 \
  --title "Release v1.0.0" \
  --notes "Release notes here" \
  --latest
```

## Workflow File Location

`.github/workflows/release.yml`

## Full Documentation

See [docs/AUTOMATED-RELEASE-MANAGEMENT.md](./AUTOMATED-RELEASE-MANAGEMENT.md) for complete documentation.
