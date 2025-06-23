#!/bin/bash

set -e

case `hostname` in
	aurora-uan-*)
		echo "Detected on Aurora"
		queue=prod
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

# Find Viskores build directory
viskores_build_dir=$scriptdir/build/viskores
if [ \! -d $viskores_build_dir ] ; then
	echo "Cannot find Viskores build dir at $viskores_build_dir"
	echo "Make sure you run this script in the same directory as make-viskores.bash"
	exit 1
fi
if [ \! -f $viskores_build_dir/bin/UnitTests_viskores_cont_testing ] ; then
	echo "Viskores tests do not seem to be built in $viskores_build_dir"
	exit 1
fi

# Set up a launch script
launch_dir=$scriptdir/launch
mkdir -p $launch_dir
launch_script=$(mktemp -p $launch_dir --suffix=-viskorestest.pbs)
echo "Launch script: $launch_script"

cat > $launch_script <<EOF
#!/bin/bash
#PBS -l select=1
#PBS -l walltime=01:00:00
#PBS -l filesystems=flare_fs
#PBS -A viskores
#PBS -q $queue
#PBS -N ViskoresTests
#PBS -o `realpath $launch_dir/viskorestest.log`
#PBS -j oe

# Load modules. Note that this script may be launched non-interactively,
# so we might need to include /etc/profile to get the module command.
. /etc/profile
. `realpath $scriptdir/setup-modules.bash`

cd `realpath $viskores_build_dir`
ctest .
EOF

qsub $launch_script

