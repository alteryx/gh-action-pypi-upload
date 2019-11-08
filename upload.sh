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

echo
echo "=================================================="
echo "Release $tag was $action on GitHub"
echo "=================================================="

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
        --username $username --password $password \
        --repository-url $repository_url
}

# If release was published on GitHub then upload to PyPI
if [ $action = "published" ]
then
    # Infer whether to use PyPI (production) or Test PyPI (development).
    repository=$(python -c "
    import re

    pattern = '(?P<version>v{n}.{n}.{n})(?P<suffix>.*)?'
    pattern = pattern.format(n='[0-9]+')
    pattern = re.compile(pattern)
    match = pattern.search('$tag')

    if match:
        match = match.groupdict()
        keys = ['version', 'suffix']
        version, suffix = map(match.get, keys)

        if version and not suffix:
            print('production')

        if version and suffix.startswith('.dev'):
            print('development')
    ")

    # Raise error if unable to make the inference for PyPI or Test PyPI.
    if [ -z $repository ]
    then
        echo "Unable to infer which PyPI repository to use."
        exit 1
    fi

    # If production, set variables for PyPI.
    if [ $repository = "production" ]
    then
        username=$PYPI_USERNAME
        password=$PYPI_PASSWORD
        repository_url="https://upload.pypi.org/legacy/"
    fi

    # If development, set variables for Test PyPI.
    if [ $repository = "development" ]
    then
        username=$TEST_PYPI_USERNAME
        password=$TEST_PYPI_PASSWORD
        repository_url="https://test.pypi.org/legacy/"
    fi

    upload_to_pypi

fi