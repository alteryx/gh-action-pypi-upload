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

upload_to_pypi() {
    # Checkout release tag
    git checkout tags/$tag

    # Upgrade pip
    pip install --user --upgrade pip

    # Install twine, module used to upload to pypi
    pip install --user twine

    # Remove build artifacts
    for artifact in ".eggs" "build" "dist"; do
    if [ -d $artifact ]; then rm -rf $artifact; fi
    done

    # Create distributions
    python setup.py sdist bdist_wheel

    # Upload to pypi or testpypi, overwrite if files already exist.
    twine upload dist/* --skip-existing --verbose \
        --username $1 --password $2 --repository-url $3
}

release() {
    # If the inferred repository is PyPI, then upload to PyPI.
    if [ "$repository" = "PyPI" ]; then
        TWINE_REPOSITORY_URL="https://upload.pypi.org/legacy/"
        upload_to_pypi $PYPI_USERNAME $PYPI_PASSWORD $TWINE_REPOSITORY_URL

    # Else if the inferred repository is Test PyPI, then upload to Test PyPI.
    elif [ "$repository" = "Test PyPI" ]; then
        TWINE_REPOSITORY_URL="https://test.pypi.org/legacy/"
        upload_to_pypi $TEST_PYPI_USERNAME $TEST_PYPI_PASSWORD $TWINE_REPOSITORY_URL

    # Else, raise an error and exit.
    else
        echo "Unable to make inference on release $tag"
        exit 1
    fi
}

# If release was published on GitHub then release to PyPI.
if [ $action = "published" ]; then release; fi