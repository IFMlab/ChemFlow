#!/bin/bash

NAME="chemflow"

_help(){
  echo "Usage: $0 onefile|onedir|pyqtdeploy"
}

clean_build(){
  if [ -d build ]; then
    rm -rf dist
    rm -rf build
  fi
  if [ -d build-linux-64 ]; then
    rm -rf build-linux-64
  fi
}

export_lib(){
  export LD_LIBRARY_PATH=${CONDA_PATH}/lib:/usr/lib
}

package_pyinstaller(){
  pyinstaller ${NAME}_${1}.spec
}

package_pyqtdeploy(){
  pyqtdeploy-build --verbose ${NAME}.pdy
  if [ -d build-linux-64 ]; then
    cd build-linux-64
    qmake
    make
    cd ..
  fi
}

case "${1,,}" in
  "-h"|"--help")
    _help
  ;;
  "onedir")
    clean_build
    export_lib
    package_pyinstaller "onedir"
  ;;
  "onefile")
    clean_build
    export_lib
    package_pyinstaller "onefile"
  ;;
  "pyqtdeploy")
    clean_build
    package_pyqtdeploy
  ;;
  *)
    echo "Error: Unknown packager $1"
    _help
  ;;
esac
