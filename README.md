# gh-action-pypi-upload
Use this GitHub action to upload a Python package to PyPi

## Prereqs 

* You can `pip install` the library locally and import it

## Usage 

Add the following lines to `.github/main.workflow`

```
workflow "Release" {
  on = "release"
  resolves = ["PyPI"]
}

action "PyPI" {
  uses = "FeatureLabs/gh-action-pypi-upload@master"
  secrets = ["PYPI_USERNAME", "PYPI_PASSWORD"]
  env = {
    TWINE_REPOSITORY_URL = "https://test.pypi.org/legacy/"
    }
}
```

*  Update `PYPI_USERNAME`, `PYPI_PASSWORD` secrets in repo settings

*Note: Once you release a version of your package to PyPi you cannot rerelease that same version number, even if you delete it*

* Make a test release and confirm the repo shows up on [TestPyPI](https://test.pypi.org/)

* If it works, change `TWINE_REPOSITORY_URL = "https://upload.pypi.org/legacy/"` to point to production PyPi server
