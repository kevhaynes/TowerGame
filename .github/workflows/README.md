# Workflows

GitHub Actions workflows.

- `ci.yml` - lint, format check, headless import and GUT tests on PRs and pushes to `main`.
- `android.yml` - debug APK on every run, signed release AAB on `v*` tags.

Signing credentials come from GitHub secrets only.
