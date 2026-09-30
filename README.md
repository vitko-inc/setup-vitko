# setup-vitko

Installs the [`vitko`](https://github.com/vitko-inc/vitko) command-line tool in a GitHub Actions job and adds it to the `PATH`.

```yaml
steps:
  - uses: vitko-inc/setup-vitko@v1
  - run: vitko runners pricing
```

Every download is checked against the release's `checksums.txt`. When the GitHub CLI is on the runner (it is on GitHub-hosted runners), the archive's GitHub build provenance is checked too. Installed versions are kept in the runner's tool cache.

## Inputs

| Input | Default | |
|---|---|---|
| `version` | `latest` | A release such as `v0.1.0`. Pin it for repeatable builds. |
| `verify-provenance` | `true` | Check build provenance when the GitHub CLI is available. |
| `token` | `${{ github.token }}` | Used to look up releases and check provenance. |

## Outputs

| Output | |
|---|---|
| `version` | The installed version. |
| `path` | Full path of the binary. |

Runs on Linux and macOS runners, x86-64 and arm64.

## License

[Apache-2.0](LICENSE)
