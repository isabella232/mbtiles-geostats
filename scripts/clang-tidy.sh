#!/usr/bin/env bash

set -eu
set -o pipefail

# https://clang.llvm.org/extra/clang-tidy/

# to speed up re-runs, only re-create environment if needed
if [[ ! -f local.env ]]; then
    # automatically setup environment
    ./scripts/setup.sh --config local.env
fi

# source the environment
source local.env

PATH_TO_CLANG_TIDY_SCRIPT="$(pwd)/mason_packages/.link/share/run-clang-tidy.py"

# to speed up re-runs, only install clang-tidy if needed
if [[ ! -f PATH_TO_CLANG_TIDY_SCRIPT ]]; then
    # The MASON_LLVM_RELEASE variable comes from `local.env`
    mason install clang-tidy ${MASON_LLVM_RELEASE}
    # We link the tools to make it easy to know ${PATH_TO_CLANG_TIDY_SCRIPT}
    mason link clang-tidy ${MASON_LLVM_RELEASE}
fi

# build the compile_commands.json file if it does not exist
if [[ ! -f build/compile_commands.json ]]; then
    # We need to clean otherwise when we make the project
    # will will not see all the compile commands
    make clean
    # Create the build directory to put the compile_commands in
    # We do this first to ensure it is there to start writing to
    # immediately (make make not create it right away)
    mkdir -p build
    # Run make, pipe the output to the generate_compile_commands.py
    # and drop them in a place that clang-tidy will automatically find them
    make | scripts/generate_compile_commands.py > build/compile_commands.json
fi

# change into the build directory so that clang-tidy can find the files
# at the right paths (since this is where the actual build happens)
cd build
${PATH_TO_CLANG_TIDY_SCRIPT} -fix

