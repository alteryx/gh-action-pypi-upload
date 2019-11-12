#!/bin/sh

# Get release tag from environment.
tag=$(basename $GITHUB_REF)

# Get action that triggered the release event.
action=$(python -c "
import json

with open('$GITHUB_EVENT_PATH', 'r') as file:
    event = json.load(file)
    action = event.get('action')

print(action)
")

# Infer whether to use PyPI or Test PyPI from the release tag.
repository=$(python -c "
import re

pattern = '(?P<version>^v\d+.\d+.\d+)'
pattern += '(?P<suffix>.*)?'
pattern = re.compile(pattern)
match = pattern.search('$tag')

if match:
    match = match.groupdict()
    keys = ['version', 'suffix']
    version, suffix = map(match.get, keys)

    if version and not suffix:
        print('PyPI')

    if version and suffix.startswith('.dev'):
        print('Test PyPI')
")

echo
echo "=================================================="
echo "Release $tag was $action on GitHub"
echo "=================================================="
echo

build_package() {
    # Checkout release tag.
    git checkout tags/$tag

    # Remove build artifacts.
    rm -rf .eggs/ rm -rf dist/ rm -rf build/

    # Create distributions
    python setup.py --quiet sdist bdist_wheel
}

upload_package() {
    # Build the package to upload.
    build_package

    # Create virtualenv to download twine.
    python -m venv venv
    . venv/bin/activate

    # Install twine which is used to upload the package.
    python -m pip install --quiet twine

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

# If release was published on GitHub then release package.
if [ $action = "published" ]; then release_package; fi