#!/bin/bash

set -e
set -u

PROJECT_ROOT="$(cd "$( dirname "$0" )"; pwd)"

# Verify that repository has been cloned with submodules

cd "$PROJECT_ROOT/lib/libelectronic-id"

[[ -e README.md ]] || { echo "FAIL: libelectronic-id submodule directory empty, did you 'git clone --recursive'?"; exit 1; }

# Build everything

cd "$PROJECT_ROOT"

BUILD_TYPE=RelWithDebInfo
#BUILD_TYPE=Release

export QT_QPA_PLATFORM=offscreen
#export OPENSSL_ROOT_DIR=/usr/local/opt/openssl@1.1
export OPENSSL_ROOT_DIR=/usr/local/opt/openssl@3
export QT_DIR=/usr/local/opt/qt6/lib/cmake/Qt6
export BUILD_TYPE
export BUILD_DIR=cmake-build-relwithdebinfo
#export BUILD_NUMBER=${{github.run_number}}
#export HOMEBREW_NO_INSTALLED_DEPENDENTS_CHECK=1
#export MAKEFLAGS=-j3
export MACOSX_DEPLOYMENT_TARGET=10.15

#lupdate src/ -ts ./src/ui/translations/*.ts
cmake -DCMAKE_BUILD_TYPE=$BUILD_TYPE  -B $BUILD_DIR -S .
cmake --build $BUILD_DIR --config $BUILD_TYPE
cmake --build $BUILD_DIR --config $BUILD_TYPE --target installer -- VERBOSE=1
#cmake --build $BUILD_DIR --config $BUILD_TYPE --target installer-safari -- VERBOSE=1
