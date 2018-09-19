#!/bin/bash

NAME="chemflow"

clean_build(){
  if [ -d build ]; then
    rm -rf dist
    rm -rf build
  fi
}

export_lib(){
  OLD_LD_LIBRARY_PATH=${LD_LIBRARY_PATH}
  export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:~/python3.6.6/lib:~/miniconda3/lib
}

unset_lib(){
  export LD_LIBRARY_PATH=${OLD_LD_LIBRARY_PATH}
}

package_pyinstaller(){
  pyinstaller ${NAME}.spec
}

clean_build
export_lib
package_pyinstaller
unset_lib
