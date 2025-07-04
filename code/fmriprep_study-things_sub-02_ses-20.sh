#!/bin/bash
#SBATCH --account=rrg-pbellec
#SBATCH --job-name=fmriprep_study-things_sub-02_ses-20.job
#SBATCH --output=/lustre04/scratch/bpinsard/cneuromod.things.fmriprep/code/fmriprep_study-things_sub-02_ses-20.out
#SBATCH --error=/lustre04/scratch/bpinsard/cneuromod.things.fmriprep/code/fmriprep_study-things_sub-02_ses-20.err
#SBATCH --time=12:00:00
#SBATCH --cpus-per-task=12
#SBATCH --mem-per-cpu=4096M
#SBATCH --tmp=100G
#SBATCH --mail-type=BEGIN
#SBATCH --mail-type=END
#SBATCH --mail-type=FAIL
#SBATCH --mail-user=basile.pinsard@gmail.com

 
set -e -u -x


export LOCAL_DATASET=$SLURM_TMPDIR/${SLURM_JOB_NAME//-/}/
export SINGULARITYENV_TEMPLATEFLOW_HOME="${LOCAL_DATASET}/sourcedata/templateflow/"
flock --verbose /lustre03/project/rrg-pbellec/ria-beluga/alias/cneuromod.things.fmriprep/.datalad_lock datalad clone ria+file:///lustre03/project/rrg-pbellec/ria-beluga#~cneuromod.things.fmriprep@base $LOCAL_DATASET
cd $LOCAL_DATASET
datalad get -s ria-beluga-storage -J 4 -n -r -R1 . # get sourcedata/* containers
datalad get -s ria-beluga-storage -J 4 -r sourcedata/templateflow/tpl-{MNI152NLin2009cAsym,OASIS30ANTs,fsLR,fsaverage,MNI152NLin6Asym}
if [ -d sourcedata/smriprep ] ; then
    datalad get -n sourcedata/smriprep sourcedata/smriprep/sourcedata/freesurfer
fi
git submodule foreach --recursive git annex dead here
git checkout -b $SLURM_JOB_NAME
if [ -d sourcedata/freesurfer ] ; then
  git -C sourcedata/freesurfer checkout -b $SLURM_JOB_NAME
fi

git submodule foreach  --recursive git-annex enableremote ria-beluga-storage

datalad containers-run -m 'fMRIPrep_sub-02/ses-20' -n containers/bids-fmriprep --input sourcedata/templateflow/tpl-MNI152NLin2009cAsym/ --input sourcedata/templateflow/tpl-OASIS30ANTs/ --input sourcedata/templateflow/tpl-fsLR/ --input sourcedata/templateflow/tpl-fsaverage/ --input sourcedata/templateflow/tpl-MNI152NLin6Asym/ --output . --input 'sourcedata/things/sub-02/ses-20/fmap/' --input 'sourcedata/things/sub-02/ses-20/func/' --input 'sourcedata/smriprep/sub-02/anat/' --input sourcedata/smriprep/sourcedata/freesurfer/fsaverage/ --input sourcedata/smriprep/sourcedata/freesurfer/sub-02/ -- -w ./workdir --participant-label 02 --anat-derivatives ./sourcedata/smriprep --fs-subjects-dir ./sourcedata/smriprep/sourcedata/freesurfer --bids-filter-file code/fmriprep_study-things_sub-02_ses-20_bids_filters.json --output-layout bids --ignore slicetiming --use-syn-sdc --output-spaces MNI152NLin2009cAsym T1w:res-iso2mm --cifti-output 91k --notrack --write-graph --skip_bids_validation --omp-nthreads 8 --nprocs 12 --mem_mb 49152 --fs-license-file code/freesurfer.license --resource-monitor sourcedata/things ./ participant 
fmriprep_exitcode=$?

flock --verbose /lustre03/project/rrg-pbellec/ria-beluga/alias/cneuromod.things.fmriprep/.datalad_lock datalad push -d ./ --to origin
if [ -d sourcedata/freesurfer ] ; then
    flock --verbose /lustre03/project/rrg-pbellec/ria-beluga/alias/cneuromod.things.fmriprep/.datalad_lock datalad push -J 4 -d sourcedata/freesurfer --to origin
fi 
if [ -e $LOCAL_DATASET/workdir/fmriprep_wf/resource_monitor.json ] ; then cp $LOCAL_DATASET/workdir/fmriprep_wf/resource_monitor.json /scratch/bpinsard/fmriprep_study-things_sub-02_ses-20_resource_monitor.json ; fi 
if [ $fmriprep_exitcode -ne 0 ] ; then cp -R $LOCAL_DATASET /scratch/bpinsard/fmriprep_study-things_sub-02_ses-20 ; fi 
exit $fmriprep_exitcode 
