#!/usr/bin/env bash

helpFunction()
{
   echo ""
   echo "Usage: $0 -i images -w workspace"
   echo -e "\t-i image folder"
   echo -e "\t-w workspace that saves intermediate data"
   exit 1 # Exit script after printing help
}

while getopts "i:w:" opt
do
   case "$opt" in
      i ) images="$OPTARG" ;;
      w ) workspace="$OPTARG" ;;
      ? ) helpFunction ;; # Print helpFunction in case parameter is non-existent
   esac
done

# Print helpFunction in case parameters are empty
if [ -z "$images" ] || [ -z "$workspace" ]
then
   echo "Some or all of the parameters are empty";
   helpFunction
fi

# ======================================================
# Begin script in case all parameters are correct
# ======================================================
echo "workspace $workspace"

colmap feature_extractor \
   --database_path $workspace/database.db \
   --image_path $images

colmap exhaustive_matcher \
   --database_path $workspace/database.db

mkdir $workspace/sparse

colmap mapper \
    --database_path $workspace/database.db \
    --image_path $images \
    --output_path $workspace/sparse

mkdir $workspace/dense

colmap image_undistorter \
    --image_path $images \
    --input_path $workspace/sparse/0 \
    --output_path $workspace/dense \
    --output_type COLMAP \
    --max_image_size 1000

# https://github.com/colmap/colmap/issues/1734
# colmap patch_match_stereo \
#     --workspace_path $workspace/dense \
#     --workspace_format COLMAP \
#     --PatchMatchStereo.geom_consistency true
colmap patch_match_stereo \
    --workspace_path $workspace/dense \
    --workspace_format COLMAP \
    --PatchMatchStereo.geom_consistency false \
    --PatchMatchStereo.num_iterations 2 \
    --PatchMatchStereo.window_radius 2 \
    --PatchMatchStereo.window_step 2 \
    --PatchMatchStereo.cache_size 8

colmap stereo_fusion \
    --workspace_path $workspace/dense \
    --workspace_format COLMAP \
    --input_type geometric \
    --output_path $workspace/dense/fused.ply

colmap poisson_mesher \
    --input_path $workspace/dense/fused.ply \
    --output_path $workspace/dense/meshed-poisson.ply

colmap delaunay_mesher \
    --input_path $workspace/dense \
    --output_path $workspace/dense/meshed-delaunay.pl
