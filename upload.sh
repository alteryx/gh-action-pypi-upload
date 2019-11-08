#!/bin/sh

# Get tag from environment
tag=$(basename $GITHUB_REF)

# Get action that triggered release event
action=$(python -c "
import json

with open('$GITHUB_EVENT_PATH', 'r') as file:
    event = json.load(file)
    action = event.get('action')

print(action)
")

# Infer the twine repository url from the tag
TWINE_REPOSITORY_URL=$(python -c "
import re

pattern = '(?P<version>v{n}.{n}.{n})(?P<suffix>.*)?'
pattern = pattern.format(n='[0-9]+')
pattern = re.compile(pattern)
match = pattern.search('$tag')

if match:
    match = match.groupdict()
    keys = ['version', 'suffix']
    version, suffix = map(match.get, keys)
    url = "https://{}.pypi.org/legacy/"

    if version and not suffix:
        print(url.format('upload'))

    if version and suffix.startswith('.dev'):
        print(url.format('test'))
")

echo
echo "=================================================="
echo "Release $tag was $action on GitHub"
echo "=================================================="
echo "TWINE_REPOSITORY_URL: $TWINE_REPOSITORY_URL"
echo

build_package() {
    # Remove build artifacts
    artifacts=( ".eggs" "dist" "build" )
    for artifact in "${artifacts[@]}"
    do
    if [ -d $artifact ]; then rm -rf $artifact; fi
    done

    # Create distributions
    python setup.py -q sdist bdist_wheel
}

upload_to_pypi() {
    # Checkout specified tag
    git checkout tags/$tag

    # Create pypi package
    build_package

    # Create virtualenv to download twine
    python -m venv venv
    . venv/bin/activate

    # Upgrade pip
    python -m pip install --upgrade pip -q

    # Install twine, module used to upload to pypi
    python -m pip install twine -q

    # Upload to pypi or testpypi, overwrite if files already exist.
    python -m twine upload dist/* --skip-existing --verbose \
        --username $PYPI_USERNAME --password $PYPI_PASSWORD \
        --repository-url $TWINE_REPOSITORY_URL
}

# If release was published on GitHub then upload to PyPI
if [ $action = "published" ]; then upload_to_pypi; fi
