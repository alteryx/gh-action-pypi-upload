#!/bin/sh

# Get release tag from environment and checkout branch.
tag=$(basename $GITHUB_REF)
git checkout tags/$tag

# Get package version.
version=$(python setup.py --version)

chmod 777 -R /github/home/.cache

# Check if release tag matches the package version.
pip install packaging==19.2 >> quiet.log; rm quiet.log

match=$(python -c "
from packaging.version import parse

match = parse('$tag') == parse('$version')
print(match)
")

if [ $match = "False" ]; then
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

    if not version.is_devrelease \
        and not version.is_postrelease \
        and not version.is_prerelease:
        print('PyPI')
")

build_package() {
    # Remove build artifacts.
    rm -rf .eggs/ rm -rf dist/ rm -rf build/

    # Create distributions.
    python setup.py sdist bdist_wheel >> quiet.log
}

upload_package() {
    # Build the package to upload.
    build_package

    # Create and activate the virtualenv to download twine.
    python -m venv venv >> quiet.log
    . venv/bin/activate

    # Upgrade pip.
    python -m pip install --upgrade pip >> quiet.log

    # Install twine which is used to upload the package.
    python -m pip install twine >> quiet.log; rm quiet.log

    echo "under development"; exit 1

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