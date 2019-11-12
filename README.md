# GitHub Action - PyPI Upload
Use this GitHub Action to upload a Python package to PyPI.

## Install

In your repository, add the following lines to `.github/workflows/release.yml`:

```yaml
on:
  release:
    types: [published]

name: Release
jobs:
  pypi:
    name: Release to PyPI
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@master
    - name: Upload to PyPI
      uses: FeatureLabs/gh-action-pypi-upload@master
      env:
        PYPI_PASSWORD: ${{ secrets.PYPI_PASSWORD }}
        PYPI_USERNAME: ${{ secrets.PYPI_USERNAME }}
        TEST_PYPI_PASSWORD: ${{ secrets.TEST_PYPI_PASSWORD }}
        TEST_PYPI_USERNAME: ${{ secrets.TEST_PYPI_USERNAME }}
```

Then, add the following secrets to the repository settings:
  - `PYPI_USERNAME`
  - `PYPI_PASSWORD`
  - `TEST_PYPI_USERNAME`
  - `TEST_PYPI_PASSWORD`

## Usage

The published release tag from GitHub will determine which repository the package is uploaded to.

### Upload to PyPI
To upload a package to [PyPI](https://pypi.org/), the release tag should follow this pattern:
- `v0.0.0`
- `v0.0.1`
- ...

### Upload to Test PyPI
To upload a package to [Test PyPI](https://test.pypi.org/), the release tag should follow this pattern:
- `v0.0.0.dev0`
- `v0.0.1.dev1`
- ...

*Note: Once you release a version of your package to PyPI, you cannot rerelease that same version number even if you delete it.*