#!/bin/bash

set -e

case `hostname` in
	aurora-uan-*)
		echo "Detected on Aurora"
		queue=EarlyAppAccess
		;;
	uan-*)
		echo "Detected on Sunspot"
		queue=workq
		;;
	*)
		echo "Cannot determine what host I am on."
		exit 1
		;;
esac

fullscriptpath=`realpath $0`
scriptdir=`dirname "$fullscriptpath"`
. $scriptdir/setup-modules.bash

# Find VTK-m build directory
vtkm_build_dir=$scriptdir/build/vtkm
if [ \! -d $vtkm_build_dir ] ; then
	echo "Cannot find VTK-m build dir at $vtkm_build_dir"
	echo "Make sure you run this script in the same directory as build-vtkm.bash"
	exit 1
fi
if [ \! -f $vtkm_build_dir/bin/UnitTests_vtkm_cont_testing ] ; then
	echo "VTK-m tests do not seem to be built in $vtkm_build_dir"
	exit 1
fi

# Set up a launch script
launch_dir=$scriptdir/launch
mkdir -p $launch_dir
launch_script=$(mktemp -p $launch_dir --suffix=-vtkmtest.pbs)
echo "Launch script: $launch_script"

cat > $launch_script <<EOF
#!/bin/bash
#PBS -l select=1
#PBS -l walltime=01:00:00
#PBS -A CSC250STDA05_CNDA
#PBS -q $queue
#PBS -N VTK-mTests
#PBS -o `realpath $launch_dir/vtkmtest.log`
#PBS -j oe

# Load modules. Note that this script may be launched non-interactively,
# so we might need to include /etc/profile to get the module command.
. /etc/profile
. `realpath $scriptdir/setup-modules.bash`

cd `realpath $vtkm_build_dir`
ctest .
EOF

qsub $launch_script

