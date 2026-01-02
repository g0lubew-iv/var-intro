mkdir -p img_enhanced

for f in img/*.jpg; do
    convert "$f" \
        -auto-level \
        -auto-gamma \
        -brightness-contrast "10x20" \
        -sharpen 0x1.5 \
        -equalize \
        "img_enhanced/$(basename "$f")"
done

rm database.db
colmap feature_extractor \
    --database_path database.db \
    --image_path img_enhanced \
    --ImageReader.camera_model SIMPLE_RADIAL \
    --ImageReader.single_camera 1 \
    --SiftExtraction.max_num_features 65536 \
    --SiftExtraction.peak_threshold 0.0001
