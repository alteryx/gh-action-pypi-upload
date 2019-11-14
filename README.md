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
        PYPI_USERNAME: ${{ secrets.PYPI_USERNAME }}
        PYPI_PASSWORD: ${{ secrets.PYPI_PASSWORD }}
        TEST_PYPI_USERNAME: ${{ secrets.TEST_PYPI_USERNAME }}
        TEST_PYPI_PASSWORD: ${{ secrets.TEST_PYPI_PASSWORD }}
```

Then, add the following secrets to the repository settings:
  - `PYPI_USERNAME`
  - `PYPI_PASSWORD`
  - `TEST_PYPI_USERNAME`
  - `TEST_PYPI_PASSWORD`

## Usage

The published release tag from GitHub will determine which repository the package is uploaded to. The tag schemes are based on the specifications in [PEP 440](https://www.python.org/dev/peps/pep-0440).

### Upload to Test PyPI

To upload a package to [Test PyPI](https://test.pypi.org/), the tag must follow the version schemes for [developmental releases](https://www.python.org/dev/peps/pep-0440/#developmental-releases).

#### Developmental releases

```
X.Y.devN          # Developmental release
X.YaN.devM        # Developmental release of an alpha release
X.YbN.devM        # Developmental release of a beta release
X.YrcN.devM       # Developmental release of a release candidate
X.Y.postN.devM    # Developmental release of a post-release
```

### Upload to PyPI

To upload a package to [PyPI](https://pypi.org/), the tag can follow version schemes for [pre-releases](https://www.python.org/dev/peps/pep-0440/#pre-releases), [final releases](https://www.python.org/dev/peps/pep-0440/#final-releases), or [post-releases](https://www.python.org/dev/peps/pep-0440/#post-releases).

#### Pre-releases

```
X.YaN     # Alpha release
X.YbN     # Beta release
X.YrcN    # Release Candidate
```

#### Final releases

```
X.Y     # Final release
```

#### Post-releases

```
X.Y.postN       # Post-release
X.YaN.postM     # Post-release of an alpha release
X.YbN.postM     # Post-release of a beta release
X.YrcN.postM    # Post-release of a release candidate
```

*Note: Once you release a version of your package to PyPI, you cannot rerelease that same version number even if you delete it.*