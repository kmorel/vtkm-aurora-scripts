#!/bin/bash

set -e

fullscriptpath=`realpath $0`
scriptdir=`dirname "$fullscriptpath"`
cd $scriptdir
. ./setup-modules.bash

buildtype=Release
#buildtype=Debug

# from Renzo on slack 02/01/2024
export IGC_FunctionCloningThreshold=1
export IGC_ControlInlineTinySize=100
export IGC_OCLInlineThreshold=200
export IGC_PartitionUnit=1
export IGC_ForceOCLSIMDWidth=16
export ZE_AFFINITY_MASK=0.0

#export PATH=/home/srizzi/bin/git-lfs-3.4.0/:$PATH
#git lfs install

export HTTP_PROXY=http://proxy.alcf.anl.gov:3128
export HTTPS_PROXY=http://proxy.alcf.anl.gov:3128
export http_proxy=http://proxy.alcf.anl.gov:3128
export https_proxy=http://proxy.alcf.anl.gov:3128
git config --global http.proxy http://proxy.alcf.anl.gov:3128

export CC=`which icx`
export CXX=`which icpx`
export WRKDIR=$PWD

echo
echo "###### CLONING REPOS ######"
echo

kokkos_repo=https://github.com/kokkos/kokkos.git
#kokkos_commit=develop
kokkos_commit=4.6.01

viskores_repo=https://github.com/Viskores/viskores.git
viskores_commit=main

if [ -d src/kokkos ] ; then
  echo "Kokkos source directory exists. Skipping."
else
  git clone -b $kokkos_commit $kokkos_repo src/kokkos
fi
if [ -d src/viskores ] ; then
  echo "Viskores source directory exists. Skipping."
else
  git clone -b $viskores_commit $viskores_repo src/viskores
  cd src/viskores
  git submodule update --init
  cd ../..
fi

#############################################                                                                                                                                                                    
# Configure and build Kokkos SYCL                                                                                                                                                                                
#############################################                                                                                                                                                                    
echo
echo "###### CONFIGURING KOKKOS ######"
echo

# Flag `-DKokkos_ENABLE_ONEDPL=OFF` added to work around bug CMPLRLLVM-60156
# in the Intel oneAPI DPC++ Library. Basically, the sort function in that
# library is broken with the IGC_ForceOCLSIMDWidth=16 compiler option. Once
# this issue is resolved, we can take out that flag.

cd $WRKDIR
cmake -G Ninja -S src/kokkos -B build/kokkos \
  -DCMAKE_BUILD_TYPE=$buildtype \
  -DCMAKE_CXX_FLAGS="-fPIC -fp-model=precise -Wno-unused-command-line-argument -Wno-deprecated-declarations -fsycl-device-code-split=per_kernel -fsycl-max-parallel-link-jobs=128 " \
  -DCMAKE_CXX_FLAGS_DEBUG="-g -O0 -fsycl-link-huge-device-code" \
  -DCMAKE_CXX_STANDARD=17 \
  -DCMAKE_CXX_EXTENSIONS=OFF \
  -DBUILD_SHARED_LIBS=ON \
  -DKokkos_ENABLE_EXAMPLES=OFF \
  -DKokkos_ENABLE_TESTS=OFF \
  -DKokkos_ENABLE_SERIAL=ON \
  -DKokkos_ENABLE_SYCL=ON \
  -DKokkos_ENABLE_ONEDPL=OFF \
  -DKokkos_ARCH_INTEL_PVC=ON \
  -DCMAKE_INSTALL_PREFIX=$WRKDIR/install/kokkos

echo
echo "###### BUILDING KOKKOS ######"
echo

cd build/kokkos
ninja
ninja install

#############################################
# Configure and build Viskores
#############################################
echo
echo "###### CONFIGURING Viskores ######"
echo

cd $WRKDIR
cmake -G Ninja -S src/viskores -B build/viskores \
  -DCMAKE_BUILD_TYPE=$buildtype \
  -DCMAKE_CXX_FLAGS="-fPIC -fp-model=precise -Wno-unused-command-line-argument -Wno-deprecated-declarations -fsycl-device-code-split=per_kernel -fsycl-max-parallel-link-jobs=128" \
  -DCMAKE_CXX_FLAGS_DEBUG="-g -O0 -fsycl-link-huge-device-code" \
  -DKokkos_DIR=$WRKDIR/install/kokkos/lib64/cmake/Kokkos \
  -DViskores_ENABLE_KOKKOS=ON \
  -DViskores_ENABLE_RENDERING=ON \
  -DViskores_ENABLE_TESTING=ON \
  -DViskores_ENABLE_TESTING_LIBRARY=ON \
  -DViskores_ENABLE_BENCHMARKS=OFF \
  -DCMAKE_INSTALL_PREFIX=$WRKDIR/install/viskores \
  -DViskores_USE_DEFAULT_TYPES_FOR_ASCENT=ON \
  -DViskores_USE_64BIT_IDS=OFF \
  -DViskores_USE_DOUBLE_PRECISION=ON

# last three settings needed for ascent

echo
echo "###### BUILDING Viskores ######"
echo

cd build/viskores
ninja
