#!/bin/bash

echo Building Google Protobuf for Mac OS X / iOS.
echo Use 'tail -f build.log' to monitor progress.

(
PREFIX=`pwd`/protobuf
mkdir ${PREFIX}
mkdir ${PREFIX}/platform

XCODEDIR=`xcode-select --print-path`

MACOSX_PLATFORM=${XCODEDIR}/Platforms/MacOSX.platform
MACOSX_SYSROOT=${MACOSX_PLATFORM}/Developer/MacOSX10.9.sdk

IPHONEOS_PLATFORM=${XCODEDIR}/Platforms/iPhoneOS.platform
IPHONEOS_SYSROOT=${IPHONEOS_PLATFORM}/Developer/SDKs/iPhoneOS7.0.sdk

IPHONESIMULATOR_PLATFORM=${XCODEDIR}/Platforms/iPhoneSimulator.platform
IPHONESIMULATOR_SYSROOT=${IPHONESIMULATOR_PLATFORM}/Developer/SDKs/iPhoneSimulator7.0.sdk

CC=clang
CFLAGS="-DNDEBUG -g -O0 -pipe -fPIC -fcxx-exceptions"
CXX=clang++
CXXFLAGS="${CFLAGS} -std=c++11 -stdlib=libc++"

####################################
# Cleanup any earlier build attempts
####################################

(
    cd /tmp
    if [ -d ${PREFIX} ]
    then
        rm -rf ${PREFIX}
    fi
    mkdir ${PREFIX}
    mkdir ${PREFIX}/platform
)

##########################################
# Fetch Google Protobuf 2.5.0 from source.
##########################################

(
    cd /tmp
    curl http://protobuf.googlecode.com/files/protobuf-2.5.0.tar.gz --output /tmp/protobuf-2.5.0.tar.gz

    if [ -d /tmp/protobuf-2.5.0 ]
    then
        rm -rf /tmp/protobuf-2.5.0
    fi
    
    tar xvf /tmp/protobuf-2.5.0.tar.gz
)

#####################
# x86_64 for Mac OS X
#####################

(
    cd /tmp/protobuf-2.5.0
    make distclean
    ./configure --disable-shared --prefix=${PREFIX} --exec-prefix=${PREFIX}/platform/x86_64 "CC=${CC}" "CFLAGS=${CFLAGS} -arch x86_64" "CXX=${CXX}" "CXXFLAGS=${CXXFLAGS} -arch x86_64"
    make
    make test
    make install
)

###########################
# i386 for iPhone Simulator
###########################

(
    cd /tmp/protobuf-2.5.0
    make distclean
    ./configure --build=x86_64-apple-darwin13.0.0 --host=i386-apple-darwin13.0.0 --with-protoc=${PREFIX}/platform/x86_64/bin/protoc --disable-shared --prefix=${PREFIX} --exec-prefix=${PREFIX}/platform/i386 "CC=${CC}" "CFLAGS=${CFLAGS} -miphoneos-version-min=6.1 -arch i386 -isysroot ${IPHONESIMULATOR_SYSROOT}" "CXX=${CXX}" "CXXFLAGS=${CXXFLAGS} -arch i386 -isysroot ${IPHONESIMULATOR_SYSROOT}" LDFLAGS="-arch i386 -miphoneos-version-min=6.1"
    make
    make install
)

##################
# armv7 for iPhone
##################

(
    cd /tmp/protobuf-2.5.0
    make distclean
    ./configure --build=x86_64-apple-darwin13.0.0 --host=armv7-apple-darwin13.0.0 --with-protoc=${PREFIX}/platform/x86_64/bin/protoc --disable-shared --prefix=${PREFIX} --exec-prefix=${PREFIX}/platform/armv7 "CC=${CC}" "CFLAGS=${CFLAGS} -miphoneos-version-min=6.1 -arch armv7 -isysroot ${IPHONEOS_SYSROOT}" "CXX=${CXX}" "CXXFLAGS=${CXXFLAGS} -arch armv7 -isysroot ${IPHONEOS_SYSROOT}" LDFLAGS="-arch armv7 -miphoneos-version-min=6.1"
    make
    make install
)

###################
# armv7s for iPhone
###################

(
    cd /tmp/protobuf-2.5.0
    make distclean
    ./configure --build=x86_64-apple-darwin13.0.0 --host=armv7s-apple-darwin13.0.0 --with-protoc=${PREFIX}/platform/x86_64/bin/protoc --disable-shared --prefix=${PREFIX} --exec-prefix=${PREFIX}/platform/armv7s "CC=${CC}" "CFLAGS=${CFLAGS} -miphoneos-version-min=6.1 -arch armv7s -isysroot ${IPHONEOS_SYSROOT}" "CXX=${CXX}" "CXXFLAGS=${CXXFLAGS} -arch armv7s -isysroot ${IPHONEOS_SYSROOT}" LDFLAGS="-arch armv7s -miphoneos-version-min=6.1"
    make
    make install
)

########################################
# Patch Protobuf 2.5.0 for 64bit support
########################################

(
    cd /tmp/protobuf-2.5.0
    make distclean
    curl https://gist.github.com/BennettSmith/7111094/raw/171695f70b102de2301f5b45d9e9ab3167b4a0e8/0001-Add-generic-GCC-support-for-atomic-operations.patch --output /tmp/0001-Add-generic-GCC-support-for-atomic-operations.patch
    curl https://gist.github.com/BennettSmith/7111094/raw/a4e85ffc82af00ae7984020300db51a62110db48/0001-Add-generic-gcc-header-to-Makefile.am.patch --output /tmp/0001-Add-generic-gcc-header-to-Makefile.am.patch
    patch -p1 < /tmp/0001-Add-generic-GCC-support-for-atomic-operations.patch
    patch -p1 < /tmp/0001-Add-generic-gcc-header-to-Makefile.am.patch
    rm /tmp/0001-Add-generic-GCC-support-for-atomic-operations.patch
    rm /tmp/0001-Add-generic-gcc-header-to-Makefile.am.patch
)

##################
# arm64 for iPhone
##################

(
    cd /tmp/protobuf-2.5.0
    ./configure --build=x86_64-apple-darwin13.0.0 --host=arm --with-protoc=${PREFIX}/platform/x86_64/bin/protoc --disable-shared --prefix=${PREFIX} --exec-prefix=${PREFIX}/platform/arm64 "CC=${CC}" "CFLAGS=${CFLAGS} -miphoneos-version-min=6.1 -arch arm64 -isysroot ${IPHONEOS_SYSROOT}" "CXX=${CXX}" "CXXFLAGS=${CXXFLAGS} -arch arm64 -isysroot ${IPHONEOS_SYSROOT}" LDFLAGS="-arch arm64 -miphoneos-version-min=6.1"
    make
    make install
)

############################
# Create Universal Libraries
############################

(
    cd ${PREFIX}/platform
    mkdir universal
    lipo x86_64/lib/libprotobuf.a arm64/lib/libprotobuf.a armv7s/lib/libprotobuf.a armv7/lib/libprotobuf.a i386/lib/libprotobuf.a -create -output universal/libprotobuf.a
    lipo x86_64/lib/libprotobuf-lite.a arm64/lib/libprotobuf-lite.a armv7s/lib/libprotobuf-lite.a armv7/lib/libprotobuf-lite.a i386/lib/libprotobuf-lite.a -create -output universal/libprotobuf-lite.a
)

######################## 
# Finalize the packaging
######################## 

(
    cd ${PREFIX}
    mkdir bin
    mkdir lib
    cp -r platform/x86_64/bin/protoc bin
    cp -r platform/x86_64/lib/* lib
    cp -r platform/universal/* lib
    #rm -rf platform
)
) >build.log 2>&1
echo Done!

