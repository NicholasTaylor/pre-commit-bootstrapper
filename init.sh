#!/bin/bash
SCRIPT_DIR="$( dirname -- "${BASH_SOURCE[0]}" )"
ORIGIN_DIR=$(pwd)
source .env

GIT_DIR=".git"

VALID_PATH=false
while [ $VALID_PATH = false ]
do
    echo "Specify the path where you want your repo to exist"
    read TARGET_DIR
    TARGET_DIR=${TARGET_DIR/#\~/$HOME}
    if mkdir -p $TARGET_DIR
    then
        echo "Creating path if not yet existant"
        VALID_PATH=true
    else
        echo "Path is either invalid or permissions are insufficient for creating a repo here."
    fi
done

#Set up config files
TEMPLATE_DIR="$SCRIPT_DIR/templates"
cd $TARGET_DIR
FLAKE_FILE=".flake8"
YAML_FILE=".pre-commit-config.yaml"
TOML_FILE="pyproject.toml"
CONFIG_FLAKE="$TEMPLATE_DIR/$FLAKE_FILE"
CONFIG_YAML="$TEMPLATE_DIR/$YAML_FILE"
CONFIG_TOML="$TEMPLATE_DIR/$TOML_FILE"
cp $CONFIG_FLAKE ./
cp $CONFIG_YAML ./
cp $CONFIG_TOML ./

#Install venv if necessary
if [ -d "$VENV_DIR" ]; then
    echo "Virtualenv directory exists. Proceeding."
else
    $PYTHON_PATH -m venv $VENV_DIR
fi


#Activate the venv
if  [[ "$OSTYPE" == "win32" ]]; then
    VENV_SUBDIR='scripts'
else
    VENV_SUBDIR='bin'
fi
. $VENV_DIR/$VENV_SUBDIR/activate


#Install pre-commit
pip install pre-commit

#Get version numbers
BLACK_VER=$(curl -s https://github.com/psf/black/tags | grep "Link--primary Link" | head -1 | sed -E 's/(.*?)(<a )(.*?)(>)(.*?)(<\/a>)(.*)/\5/')
FLAKE8_VER=$(curl -s https://github.com/PyCQA/flake8/tags | grep "Link--primary Link" | head -1 | sed -E 's/(.*?)(<a )(.*?)(>)(.*?)(<\/a>)(.*)/\5/')
PYTHON_VER=python$(python --version | sed -E 's/(.*?)([0-9]+\.[0-9]+)(\..*)/\2/')

#Initialize Git repo if necessary
if [ -d "$GIT_DIR" ]; then
    echo "Git repo exists. Proceeding."
else
    git init
fi

#Set up config files
cp $CONFIG_FLAKE ./
cp $CONFIG_YAML ./
cp $CONFIG_TOML ./
sed -i -e "s/BLACK_VER/$BLACK_VER/" $YAML_FILE
sed -i -e "s/FLAKE8_VER/$FLAKE8_VER/" $YAML_FILE
sed -i -e "s/PYTHON_VER/$PYTHON_VER/" $YAML_FILE

pre-commit install
deactivate

cd $ORIGIN_DIR

unset SCRIPT_DIR ORIGIN_DIR GIT_DIR VALID_PATH TARGET_DIR TEMPLATE_DIR FLAKE_FILE YAML_FILE TOML_FILE CONFIG_FLAKE CONFIG_YAML CONFIG_TOML VENV_SUBDIR BLACK_VER FLAKE8_VER PYTHON_VER PYTHON_PATH VENV_DIR