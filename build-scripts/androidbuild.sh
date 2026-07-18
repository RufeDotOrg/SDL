#!/bin/bash

# Single-source Android project scaffold for org.rufe apps.
# Usage: androidbuild.sh src/<file>.c
#   any src/<file>.c is fine; package = org.rufe.<file>
#   jni/src = symlink to cwd (project root; expects Android.mk there)
# Put this script back under $SDL/build-scripts/ so SDLPATH resolves.
# COPYSOURCE=1 copies SDL source instead of symlinking.

if [ -z "$1" ] || [ -n "$2" ]; then
    echo "Usage: androidbuild.sh src/<file>.c"
    echo "package is org.rufe.<file>"
    echo "  src/tree.c  -> org.rufe.tree"
    echo "  src/paint.c -> org.rufe.paint"
    echo "Run from project root: jni/src becomes a symlink to cwd"
    echo "COPYSOURCE=1 androidbuild.sh ...  copies SDL instead of symlink"
    exit 1
fi

SRC="$1"
CURDIR=`pwd -P`

if [ ! -f "$SRC" ]; then
    echo "Source not found: $SRC"
    exit 1
fi

BASE=$(basename "$SRC" .c)
APP="org.rufe.$BASE"
APPARR=(${APP//./ })
MKSOURCES="$SRC"

SDLPATH="$( cd "$(dirname "$0")/.." ; pwd -P )"

if [ -z "$ANDROID_HOME" ];then
    echo "Please set the ANDROID_HOME directory to the path of the Android SDK"
    exit 1
fi

if [ ! -d "$ANDROID_HOME/ndk-bundle" -a -z "$ANDROID_NDK_HOME" ]; then
    echo "Please set the ANDROID_NDK_HOME directory to the path of the Android NDK"
    exit 1
fi

BUILDPATH="$SDLPATH/build/$APP"

# Start Building

rm -rf $BUILDPATH
mkdir -p $BUILDPATH

cp -r $SDLPATH/android-project/* $BUILDPATH

# Copy SDL sources
mkdir -p $BUILDPATH/app/jni/SDL
if [ -z "$COPYSOURCE" ]; then
    ln -s $SDLPATH/src $BUILDPATH/app/jni/SDL
    ln -s $SDLPATH/include $BUILDPATH/app/jni/SDL
else
    cp -r $SDLPATH/src $BUILDPATH/app/jni/SDL
    cp -r $SDLPATH/include $BUILDPATH/app/jni/SDL
fi

cp -r $SDLPATH/Android.mk $BUILDPATH/app/jni/SDL
sed -i -e "s|org\.libsdl\.app|$APP|g" $BUILDPATH/app/build.gradle
sed -i -e "s|org\.libsdl\.app|$APP|g" $BUILDPATH/app/src/main/AndroidManifest.xml

# Project root is jni/src (replaces template dir + source copy)
rm -rf $BUILDPATH/app/jni/src
ln -s "$CURDIR" $BUILDPATH/app/jni/src

# Point project Android.mk at this source (path relative to cwd / jni/src)
if [ -f "$CURDIR/Android.mk" ]; then
    sed -i -e "s|^LOCAL_SRC_FILES :=.*|LOCAL_SRC_FILES :=  $MKSOURCES|" "$CURDIR/Android.mk"
fi

# Create an inherited Activity
cd $BUILDPATH/app/src/main/java
for folder in "${APPARR[@]}"
do
    mkdir -p $folder
    cd $folder
done

ACTIVITY="${folder}Activity"
sed -i -e "s|\"SDLActivity\"|\"$ACTIVITY\"|g" $BUILDPATH/app/src/main/AndroidManifest.xml

# Fill in a default Activity
cat >"$ACTIVITY.java" <<__EOF__
package $APP;

import org.libsdl.app.SDLActivity;

public class $ACTIVITY extends SDLActivity
{
}
__EOF__

# Update project and build
echo "Package: $APP"
echo "jni/src -> $CURDIR"
echo "To build and install to a device for testing, run the following:"
echo "cd $BUILDPATH"
echo "./gradlew installDebug"
