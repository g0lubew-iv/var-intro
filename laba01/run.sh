#!/bin/bash
# Фотограмметрия с COLMAP
# Используется датасет South Building

echo "South Building - start..."

# FEATURE EXTRACTION

colmap feature_extractor \
    --database_path database.db \
    --image_path south-building/images \
    --ImageReader.camera_model SIMPLE_RADIAL \
    --ImageReader.single_camera 1 2>&1 | grep -E "(Extracted|images)" || true

FEATURES=$(sqlite3 database.db "SELECT SUM(rows) FROM keypoints;" 2>/dev/null || echo "0")
IMAGES_IN_DB=$(sqlite3 database.db "SELECT COUNT(*) FROM images;" 2>/dev/null || echo "0")
echo "Извлечено признаков: $FEATURES"
echo "Обработано изображений: $IMAGES_IN_DB/$IMAGE_COUNT"

# FEATURE MATCHING

colmap vocab_tree_matcher \
    --database_path database.db \
    --VocabTreeMatching.num_images 100 \
    --VocabTreeMatching.num_nearest_neighbors 50

MATCHES=$(sqlite3 database.db "SELECT COUNT(*) FROM matches;" 2>/dev/null || echo "0")
echo "Найдено соответствий: $MATCHES"

# SPARSE RECONSTRUCTION
mkdir -p sparse

colmap mapper \
    --database_path database.db \
    --image_path south-building/images \
    --output_path sparse \
    --HierarchicalMapper.init_num_reg_models 2

# visualize
mkdir -p visualization

colmap model_converter \
    --input_path sparse/0 \
    --output_path visualization/sparse_model.ply \
    --output_type PLY 2>/dev/null && echo "have: sparse_model.ply"

colmap model_converter \
    --input_path sparse/0 \
    --output_path visualization/sparse_model.txt \
    --output_type TXT 2>/dev/null && echo "have: sparse_model.txt"

# DENSE RECONSTRUCTION

# you might want to check CUDA!!
mkdir -p dense

echo "Undistortion..."
colmap image_undistorter \
    --image_path south-building/images \
    --input_path sparse/0 \
    --output_path dense \
    --max_image_size 1200 2>&1 | tail -5

echo "Patch Match Stereo..."
colmap patch_match_stereo \
    --workspace_path dense \
    --PatchMatchStereo.max_image_size 1200 \
    --PatchMatchStereo.window_radius 5 \
    --PatchMatchStereo.num_iterations 3 2>&1 | tail -10

echo "Stereo Fusion..."
colmap stereo_fusion \
    --workspace_path dense \
    --output_path dense/fused.ply \
    --input_type geometric 2>&1 | tail -5

DENSE_POINTS=$(head -20 dense/fused.ply | grep "element vertex" | awk '{print $3}')
echo "dense model: $DENSE_POINTS точек"
echo "location: dense/fused.ply ($(du -h dense/fused.ply | cut -f1))"
