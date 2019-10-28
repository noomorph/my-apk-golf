#!/bin/bash
# A Simple Script to build a simple APK without ant/gradle
# Copyright 2016 Wanghong Lin 
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
# 	http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# 

# create a simple Android application to test this script
# 
# $ android create project -n MyApplication -p MyApplication -k com.example -a MainActivity --target 8
#
# copy this script to the root of your Android project and run

[ x$ANDROID_SDK_ROOT == x ] && {
    printf '\e[31mANDROID_SDK_ROOT not set\e[30m\n'
	exit 1
}

[ ! -d $ANDROID_SDK_ROOT ] && {
    printf "\e[31mInvalid ANDROID_SDK_ROOT ---> $ANDROID_SDK_ROOT\e[30m\n"
	exit 1
}

# use the latest build tool version
# and the oldest platform version for compatibility
_BUILD_TOOLS_VERSION=$(ls $ANDROID_SDK_ROOT/build-tools | sort -n |tail -1)
_OLDEST_PLATFORM=$(ls $ANDROID_SDK_ROOT/platforms | sort -nr |tail -1)
_APK_BASENAME=MiniApp
_APK_FINAL_NAME=MiniApp.apk

_ANDROID_CLASSPATH=$ANDROID_SDK_ROOT/platforms/$_OLDEST_PLATFORM/android.jar
_AAPT=$ANDROID_SDK_ROOT/build-tools/$_BUILD_TOOLS_VERSION/aapt
_DX=$ANDROID_SDK_ROOT/build-tools/$_BUILD_TOOLS_VERSION/dx
_ZIPALIGN=$ANDROID_SDK_ROOT/build-tools/$_BUILD_TOOLS_VERSION/zipalign
_ADB=$ANDROID_SDK_ROOT/platform-tools/adb
_INTERMEDIATE_FILES_GLOB="bin gen ${_APK_BASENAME}.apk.unaligned"
_APP_ANDROID_MANIFEST=app/src/main/AndroidManifest.xml
_APP_DEBUG_KEYSTORE_PATH=$HOME/.android/debug.keystore
_APP_KEYSTORE_PATH=$HOME/jocker_batman.keystore
_APP_KEYSTORE_PASS=jocker
_APP_KEYSTORE_KEY_NAME=upload
_APP_KEYSTORE_KEY_PASS=batman

printf "\e[32mBuild with configuration: \n\tbuild tools version: $_BUILD_TOOLS_VERSION \n\tplatform: $_OLDEST_PLATFORM\e[30m\n"

rm -rf $_INTERMEDIATE_FILES_GLOB
mkdir bin gen

# -f: force overwrite of existing files
# -m: make package directories under location specified by -J
# -J: specify where to output R.java resource constant definitions
# -M: specify full path to AndroidManifest.xml to include in zip
# -S: directory in which to find resources
# -I: add an existing package to base include set
# Original command: $_AAPT package -f -m -J gen -M AndroidManifest.xml -S res -I $_ANDROID_CLASSPATH
# NOTE: Apparently, it does not create R.java (as promised), because there are no resources
$_AAPT package -f -m -J gen -M $_APP_ANDROID_MANIFEST -I $_ANDROID_CLASSPATH

# -bootclasspath: Override location of bootstrap class files
# -classpath: Specify where to find user class files and annotation processors
# -sourcepath: Specify where to find input source files
# NOTE: for -classpath and -sourcepath, in *nix operating systems the classpath separator is ":" instead of ";".
# -d: Specify where to place generated class files
# -target: Generate class files for specific VM version
# -source: Provide source compatibility with specified release
# NOTE: rt.jar is probably runtime jar, but I am not sure

javac -classpath $_ANDROID_CLASSPATH \
  -bootclasspath "/Applications/Android Studio.app/Contents/jre/jdk/Contents/Home/jre/lib/rt.jar" \
	-sourcepath 'app/src/main:gen' \
	-d 'bin' -target 1.7 -source 1.7 \
	`find app/src/main -name "*.java"`

$_DX --dex --output=classes.dex bin

# Original command: $_AAPT package -f -M $_APP_ANDROID_MANIFEST -S res -I $_ANDROID_CLASSPATH -F ${_APK_BASENAME}.apk.unaligned
# -F:  specify the apk file to output
# NOTE: removed -S res (we have no resources)
# NOTE: it has no -m and -J flags contrary to the previous call
$_AAPT package -f -M $_APP_ANDROID_MANIFEST -I $_ANDROID_CLASSPATH -F ${_APK_BASENAME}.apk.unaligned

# Add specified files to Zip-compatible archive.
$_AAPT add ${_APK_BASENAME}.apk.unaligned classes.dex

# Sign the APK, obviously ¯\_(ツ)_/¯
# It yields warning about Trusted Timestamping
# NOTE: commented out because why not? it is just a debug key
# jarsigner \
#   -tsa http://timestamp.digicert.com \
#   -keystore "$_APP_DEBUG_KEYSTORE_PATH" \
#   -storepass 'android' \
#   "${_APK_BASENAME}.apk.unaligned" \
#   androiddebugkey

# Create a release version with your keys
jarsigner \
  -tsa http://timestamp.digicert.com \
  -keystore "$_APP_KEYSTORE_PATH" \
  -storepass "$_APP_KEYSTORE_PASS" \
  -keypass "$_APP_KEYSTORE_KEY_PASS" \
  "${_APK_BASENAME}.apk.unaligned" \
  "$_APP_KEYSTORE_KEY_NAME"

# KEY NAME is an important parameter, because when we sign the same APK twice,
# then we add there META-INF/<KEY-NAME>.{RSA, SF} files.
# So, at the end, we have
# META-INF/ANDROIDD.RSA
# META-INF/ANDROIDD.SF
# META-INF/UPLOAD.RSA
# META-INF/UPLOAD.SF
# and there is MANIFEST.MF which is unchanged (it has SHA sums for all files in APK)

# Zip align: TODO: read more
$_ZIPALIGN -f 4 "${_APK_BASENAME}.apk.unaligned" "${_APK_FINAL_NAME}"

rm -rf $_INTERMEDIATE_FILES_GLOB

# Try installing the app
$_ADB devices | tail -n +2 | cut -sf 1 | xargs -I {} adb -s {} install -r "${_APK_FINAL_NAME}"
