#!/usr/bin/env bash

CONVERT_CMD=`which convert`
SRC_IMAGE=$1
PWD=`pwd`
ALPHA="on"
TRANSPARENT_COLOUR="#FFF"
IMAGE_NAME="favicon"
ICON_DIR="icon"
ICON_SIZES=(72 96 128 144 152 192 384 512)
FAVICON_SIZES=(16 32 96)
APPLE_SIZES=(16 20 29 32 40 48 50 55 57 58 60 64 72 80 87 88 100 114 152 167 172 180 196 256 512)
APPLE_PRECOMPOSED=192
APPLE_ICON=192
MS_SIZES=(70 144 150 310)
ANDROID_SIZES=(36 48 72 96 114 192 512)

if [ -z $CONVERT_CMD ] || [ ! -f $CONVERT_CMD ] || [ ! -x $CONVERT_CMD ];
then
    echo "ImageMagick needs to be installed to run this script"
    exit;
fi

if [ -z $SRC_IMAGE ];
then
    echo "You must supply a source image as the argument to this command."
    exit;
fi

if [ ! -f $SRC_IMAGE ];
then
    echo "Source image \"$SRC_IMAGE\" does not exist."
    exit;
fi

function generate_png {
    local NAME=$1
    local SOURCE=$2
    local SIZE=$3
    local DIR=$4

    if [ ! -f "$SOURCE" ];
    then
        echo "Could not find the source image $SOURCE"
        exit 1;
    fi

    if [[ $SIZE =~ ^([0-9]+)x([0-9]+)$ ]];
    then
        WIDTH=${BASH_REMATCH[1]}
        HEIGHT=${BASH_REMATCH[2]}
    else
        WIDTH=$SIZE
        HEIGHT=$SIZE
    fi

    RADIUS=$(expr ${SIZE} \* 10 / 57)

    if [ ! -z "$DIR" ]
    then 
        echo "$DIR/$NAME.${SIZE}.png with radius of ${RADIUS}"
        $CONVERT_CMD "$SOURCE" \
          -resize ${WIDTH}x${HEIGHT}! \
          -crop ${WIDTH}x${HEIGHT}+0+0 \
           \( +clone  -alpha extract \
            -draw "fill black polygon 0,0 0,${RADIUS} ${RADIUS},0 fill white circle ${RADIUS},${RADIUS} ${RADIUS},0" \
            \( +clone -flip \) -compose Multiply -composite \
            \( +clone -flop \) -compose Multiply -composite \
           \) -alpha off -compose CopyOpacity -composite  "$PWD/$DIR/$NAME.${SIZE}.png"
    else
        echo "$NAME-${SIZE}x${SIZE}.png with radius of ${RADIUS}"
           $CONVERT_CMD "$SOURCE" \
          -resize ${WIDTH}x${HEIGHT}! \
          -crop ${WIDTH}x${HEIGHT}+0+0 \
           \( +clone  -alpha extract \
            -draw "fill black polygon 0,0 0,${RADIUS} ${RADIUS},0 fill white circle ${RADIUS},${RADIUS} ${RADIUS},0" \
            \( +clone -flip \) -compose Multiply -composite \
            \( +clone -flop \) -compose Multiply -composite \
           \) -alpha off -compose CopyOpacity -composite  "$PWD/$NAME-${SIZE}x${SIZE}.png"
    fi
} 

echo "Generating icons"

if [ ! -d "$ICON_DIR" ]
then 
    echo "No icon directory, creating /$ICON_DIR"
    mkdir "$ICON_DIR"
fi
for size in "${ICON_SIZES[@]}"
do
   generate_png "icon" $SRC_IMAGE $size $ICON_DIR
done

echo "Generating apple icons"
for size in "${APPLE_SIZES[@]}"
do
   generate_png "apple-icon" $SRC_IMAGE $size 
done
echo "apple-icon-precomposed.png"
$CONVERT_CMD "$SRC_IMAGE" -resize ${APPLE_PROCOMPOSED}x${APPLE_PROCOMPOSED}! -crop ${APPLE_PROCOMPOSED}x${APPLE_PROCOMPOSED}+0+0 -alpha on "$PWD/apple-icon-precomposed.png"
echo "apple-icon.png"
$CONVERT_CMD "$SRC_IMAGE" -resize ${APPLE_ICON}x${APPLE_ICON}! -crop ${APPLE_ICON}x${APPLE_ICON}+0+0 -alpha on "$PWD/apple-icon.png"

echo "Generating android icons"
for size in "${ANDROID_SIZES[@]}"
do
   generate_png "android-icon" $SRC_IMAGE $size 
done

echo "Generating ms icons"
for size in "${MS_SIZES[@]}"
do
   generate_png "ms-icon" $SRC_IMAGE $size 
done

echo "Generating favicons"
for size in "${FAVICON_SIZES[@]}"
do
   generate_png "favicon" $SRC_IMAGE $size 
done
echo "favicon.ico"
$CONVERT_CMD "$SRC_IMAGE" -resize 16x16! -crop 16x16+0+0 -background $TRANSPARENT_COLOUR -alpha remove "$PWD/favicon.ico"