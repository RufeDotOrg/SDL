
# Uncomment this if you're using STL in your project
# You can find more information here:
# https://developer.android.com/ndk/guides/cpp-support
# APP_STL := c++_shared
APP_STL := none

# Support Android 16K pagesize
APP_CFLAGS += -z max-page-size=16384
# Math options
APP_CFLAGS += -fno-math-errno -ffp-contract=fast -freciprocal-math -fno-trapping-math

APP_ABI := armeabi-v7a arm64-v8a x86 x86_64

# Min runtime API level
APP_PLATFORM=android-26
