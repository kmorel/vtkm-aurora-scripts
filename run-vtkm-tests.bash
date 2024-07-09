#!/bin/bash

# Find VTK-m build directory
vtkm_build_dir=`pwd`/build/vtkm
if [ \! -d $vtkm_build_dir ] ; then
	echo "Cannot find VTK-m build dir at $vtkm_build_dir"
	exit 1
fi
if [ \! -f $vtkm_build_dir/bin/UnitTests_vtkm_cont_testing ] ; then
	echo "VTK-m tests do not seem to be built in $vtkm_build_dir"
	exit 1
fi

# Set up a launch script
launch_dir=`pwd`/launch
mkdir -p $launch_dir
launch_script=$(mktemp -p $launch_dir --suffix=-vtkmtest.pbs)
echo "Launch script: $launch_script"

cat > $launch_script <<EOF
#!/bin/bash
#PBS -l select=1
#PBS -l walltime=00:15:00
#PBS -A CSC250STDA05
#PBS -q workq
#PBS -N VTK-mTests
#PBS -o $launch_dir/vtkmtest.log
#PBS -j oe

cd $vtkm_build_dir
ctest .
EOF

qsub $launch_script

