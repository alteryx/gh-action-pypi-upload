#!/bin/sh

# Get release tag from environment and checkout branch.
tag=$(basename $GITHUB_REF)
git checkout tags/$tag

# Get package version.
version=$(python setup.py --version)

# Check if release tag matches the package version.
pip install --quiet packaging==19.2

match=$(python -c "
from packaging.version import parse

match = parse('$tag') == parse('$version')
print(match)
")

if [ $match != "True" ]; then
    echo "Release $tag does not match package $version"
    exit 1
fi

# Get action that triggered event.
action=$(python -c "
import json

with open('$GITHUB_EVENT_PATH', 'r') as file:
    event = json.load(file)
    action = event.get('action')

print(action)
")

# Infer which repository to use.
repository=$(python -c "
from packaging.version import parse, Version

version = parse('$tag')
if isinstance(version, Version):
    if version.is_devrelease:
        print('Test PyPI')

    else: print('PyPI')
")

build_package() {
    # Remove build artifacts.
    rm -rf .eggs/ rm -rf dist/ rm -rf build/

    # Create distributions.
    python setup.py --quiet sdist bdist_wheel
}

upload_package() {
    # Build the package to upload.
    build_package

    # Create and activate the virtualenv to download twine.
    python -m venv venv; . venv/bin/activate

    # Upgrade pip.
    python -m pip install --quiet --upgrade pip

    # Install twine which is used to upload the package.
    python -m pip --quiet install twine

    # Upload the package to PyPI or Test PyPI. Overwrite if files already exist.
    python -m twine upload dist/* --skip-existing --verbose \
       --username $1 --password $2 --repository-url $3
}

release_package() {
    # If the inferred repository is PyPI, then release to PyPI.
    if [ "$repository" = "PyPI" ]; then
        TWINE_REPOSITORY_URL="https://upload.pypi.org/legacy/"
        upload_package $PYPI_USERNAME $PYPI_PASSWORD $TWINE_REPOSITORY_URL

    # Else if the inferred repository is Test PyPI, then release to Test PyPI.
    elif [ "$repository" = "Test PyPI" ]; then
        TWINE_REPOSITORY_URL="https://test.pypi.org/legacy/"
        upload_package $TEST_PYPI_USERNAME $TEST_PYPI_PASSWORD $TWINE_REPOSITORY_URL

    # Else, raise an error and exit.
    else
        echo "Unable to make inference on release $tag"
        exit 1
    fi
}

echo
echo "=================================================="
echo "Release $tag was $action on GitHub"
echo "=================================================="
echo

# If release was published on GitHub then release package.
if [ $action = "published" ]; then release_package; fi