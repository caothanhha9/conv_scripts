#!/bin/bash
  
# Author: Sasha Nikiforov

# source of inspiration
# https://stackoverflow.com/questions/41293077/how-to-compile-tensorflow-with-sse4-2-and-avx-instructions

raw_cpu_flags=`sysctl -a | grep machdep.cpu.features | cut -d ":" -f 2 | tr '[:upper:]' '[:lower:]'`
COPT="--copt=-march=native"

for cpu_feature in $raw_cpu_flags
do
    case "$cpu_feature" in
        "sse4.1" | "sse4.2" | "ssse3" | "fma" | "cx16" | "popcnt" | "maes")
            COPT+=" --copt=-m$cpu_feature"
        ;;
        "avx1.0")
            COPT+=" --copt=-mavx"
        ;;
        *)
            # noop
        ;;
    esac
done

mkdir /tmp/tensorflow_pkg
chmod 777 /tmp/tensorflow_pkg

bazel clean
PYTHON_BIN_PATH=/usr/bin/python3 PYTHON_LIB_PATH=/usr/local/lib/python3.5/dist-packages TF_DOWNLOAD_CLANG=0 TF_NEED_CUDA=0 TF_NEED_OPENCL_SYCL=0 ./configure
bazel build --cxxopt="-D_GLIBCXX_USE_CXX11_ABI=0" --incompatible_remove_native_http_archive=false --incompatible_package_name_is_a_function=false -c opt $COPT -k //tensorflow/tools/pip_package:build_pip_package
bazel-bin/tensorflow/tools/pip_package/build_pip_package /tmp/tensorflow_pkg

pip3 install --upgrade /tmp/tensorflow_pkg/`ls /tmp/tensorflow_pkg/ | grep tensorflow`

