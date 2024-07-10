#!/bin/bash

fullscriptpath=`realpath $0`
scriptdir=`dirname "$fullscriptpath"`
. $scriptdir/setup-modules.bash

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

git clone -b develop https://github.com/kokkos/kokkos.git src/kokkos
git clone https://gitlab.kitware.com/vtk/vtk-m.git src/vtk-m
cd src/vtk-m
git lfs checkout
cd ../..

#############################################                                                                                                                                                                    
# Configure and build Kokkos SYCL                                                                                                                                                                                
#############################################                                                                                                                                                                    
echo
echo "###### CONFIGURING KOKKOS ######"
echo

cd $WRKDIR
cmake -G Ninja -S src/kokkos -B build/kokkos \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_CXX_FLAGS="-fPIC -fp-model=precise -Wno-unused-command-line-argument -Wno-deprecated-declarations -fsycl-device-code-split=per_kernel -fsycl-max-parallel-link-jobs=128 " \
  -DCMAKE_CXX_FLAGS_DEBUG="-g -O0 -fsycl-link-huge-device-code" \
  -DCMAKE_CXX_STANDARD=17 \
  -DCMAKE_CXX_EXTENSIONS=OFF \
  -DBUILD_SHARED_LIBS=ON \
  -DKokkos_ENABLE_EXAMPLES=OFF \
  -DKokkos_ENABLE_TESTS=OFF \
  -DKokkos_ENABLE_SERIAL=ON \
  -DKokkos_ENABLE_SYCL=ON \
  -DKokkos_ARCH_INTEL_PVC=ON \
  -DCMAKE_INSTALL_PREFIX=$WRKDIR/install/kokkos

echo
echo "###### BUILDING KOKKOS ######"
echo

cd build/kokkos
ninja
ninja install

#############################################                                                                                                                                                                    
# Configure and build VTK-m                                                                                                                                                                                      
#############################################                                                                                                                                                                    
echo
echo "###### CONFIGURING VTK-m ######"
echo

cd $WRKDIR
cmake -G Ninja -S src/vtk-m -B build/vtkm \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_CXX_FLAGS="-fPIC -fp-model=precise -Wno-unused-command-line-argument -Wno-deprecated-declarations -fsycl-device-code-split=per_kernel -fsycl-max-parallel-link-jobs=128" \
  -DCMAKE_CXX_FLAGS_DEBUG="-g -O0 -fsycl-link-huge-device-code" \
  -DKokkos_DIR=$WRKDIR/install/kokkos/lib64/cmake/Kokkos \
  -DVTKm_ENABLE_KOKKOS=ON \
  -DVTKm_ENABLE_RENDERING=ON \
  -DVTKm_ENABLE_TESTING=ON \
  -DVTKm_ENABLE_TESTING_LIBRARY=ON \
  -DVTKm_ENABLE_BENCHMARKS=OFF \
  -DCMAKE_INSTALL_PREFIX=$WRKDIR/install/vtkm \
  -DVTKm_USE_DEFAULT_TYPES_FOR_ASCENT=ON \
  -DVTKm_USE_64BIT_IDS=OFF \
  -DVTKm_USE_DOUBLE_PRECISION=ON

# last three settings needed for ascent

echo
echo "###### BUILDING VTK-m ######"
echo

cd build/vtkm
ninja

