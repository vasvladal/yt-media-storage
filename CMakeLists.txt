# This file is part of yt-media-storage, a tool for encoding media.
# Copyright (C) Brandon Li <https://brandonli.me/>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

cmake_minimum_required(VERSION 3.22)
project(media_storage LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(OpenMP REQUIRED)
find_package(Qt6 REQUIRED COMPONENTS Core Widgets)

# Enable Qt MOC, UIC, and RCC for GUI only
set(CMAKE_AUTOMOC OFF)
set(CMAKE_AUTOUIC OFF)
set(CMAKE_AUTORCC OFF)

# -------------------------------------------------------------------
# Find FFmpeg components directly (no pkg-config required)
# -------------------------------------------------------------------

# Set default vcpkg installation path (modify if your vcpkg is elsewhere)
set(VCPKG_INSTALL_PATH "C:/dev/vcpkg/installed/x64-windows" CACHE PATH "Path to vcpkg installed libraries")

# Helper macro to find FFmpeg components
macro(find_ffmpeg_component COMPONENT HEADER LIB)
    set(${COMPONENT}_INCLUDE_DIR ${VCPKG_INSTALL_PATH}/include CACHE INTERNAL "")
    find_path(${COMPONENT}_INCLUDE_DIR_DETAIL
        NAMES lib${COMPONENT}/${HEADER}
        PATHS ${VCPKG_INSTALL_PATH}/include
        NO_DEFAULT_PATH
        REQUIRED
    )
    
    find_library(${COMPONENT}_LIBRARY
        NAMES ${LIB} ${LIB}.lib
        PATHS ${VCPKG_INSTALL_PATH}/lib
        NO_DEFAULT_PATH
        REQUIRED
    )
    
    if(${COMPONENT}_INCLUDE_DIR_DETAIL AND ${COMPONENT}_LIBRARY)
        set(${COMPONENT}_FOUND TRUE)
        message(STATUS "Found ${COMPONENT}: ${${COMPONENT}_LIBRARY}")
    else()
        set(${COMPONENT}_FOUND FALSE)
        message(FATAL_ERROR "Could not find ${COMPONENT}")
    endif()
endmacro()

# Find all required FFmpeg components
find_ffmpeg_component(avcodec avcodec.h avcodec)
find_ffmpeg_component(avformat avformat.h avformat)
find_ffmpeg_component(avutil avutil.h avutil)
find_ffmpeg_component(swscale swscale.h swscale)
find_ffmpeg_component(swresample swresample.h swresample)

# -------------------------------------------------------------------
# Find libsodium
# -------------------------------------------------------------------
find_path(SODIUM_INCLUDE_DIR
    NAMES sodium.h
    PATHS ${VCPKG_INSTALL_PATH}/include
    NO_DEFAULT_PATH
    REQUIRED
)

find_library(SODIUM_LIBRARY
    NAMES sodium libsodium
    PATHS ${VCPKG_INSTALL_PATH}/lib
    NO_DEFAULT_PATH
    REQUIRED
)

if(SODIUM_INCLUDE_DIR AND SODIUM_LIBRARY)
    set(SODIUM_FOUND TRUE)
    message(STATUS "Found libsodium: ${SODIUM_LIBRARY}")
else()
    message(FATAL_ERROR "Could not find libsodium")
endif()

# -------------------------------------------------------------------
# Create IMPORTED targets for all libraries
# -------------------------------------------------------------------

# FFmpeg targets
add_library(FFmpeg::avcodec UNKNOWN IMPORTED)
set_target_properties(FFmpeg::avcodec PROPERTIES
    IMPORTED_LOCATION "${avcodec_LIBRARY}"
    INTERFACE_INCLUDE_DIRECTORIES "${avcodec_INCLUDE_DIR_DETAIL}"
)

add_library(FFmpeg::avformat UNKNOWN IMPORTED)
set_target_properties(FFmpeg::avformat PROPERTIES
    IMPORTED_LOCATION "${avformat_LIBRARY}"
    INTERFACE_INCLUDE_DIRECTORIES "${avformat_INCLUDE_DIR_DETAIL}"
)

add_library(FFmpeg::avutil UNKNOWN IMPORTED)
set_target_properties(FFmpeg::avutil PROPERTIES
    IMPORTED_LOCATION "${avutil_LIBRARY}"
    INTERFACE_INCLUDE_DIRECTORIES "${avutil_INCLUDE_DIR_DETAIL}"
)

add_library(FFmpeg::swscale UNKNOWN IMPORTED)
set_target_properties(FFmpeg::swscale PROPERTIES
    IMPORTED_LOCATION "${swscale_LIBRARY}"
    INTERFACE_INCLUDE_DIRECTORIES "${swscale_INCLUDE_DIR_DETAIL}"
)

add_library(FFmpeg::swresample UNKNOWN IMPORTED)
set_target_properties(FFmpeg::swresample PROPERTIES
    IMPORTED_LOCATION "${swresample_LIBRARY}"
    INTERFACE_INCLUDE_DIRECTORIES "${swresample_INCLUDE_DIR_DETAIL}"
)

# libsodium target
add_library(Sodium::sodium UNKNOWN IMPORTED)
set_target_properties(Sodium::sodium PROPERTIES
    IMPORTED_LOCATION "${SODIUM_LIBRARY}"
    INTERFACE_INCLUDE_DIRECTORIES "${SODIUM_INCLUDE_DIR}"
)

# -------------------------------------------------------------------
# Executables
# -------------------------------------------------------------------
add_executable(media_storage)
add_executable(media_storage_gui WIN32)

add_subdirectory(src)

target_link_libraries(media_storage PRIVATE
    FFmpeg::avcodec
    FFmpeg::avformat
    FFmpeg::avutil
    FFmpeg::swscale
    FFmpeg::swresample
    Sodium::sodium
    OpenMP::OpenMP_CXX
)

target_link_libraries(media_storage_gui PRIVATE
    FFmpeg::avcodec
    FFmpeg::avformat
    FFmpeg::avutil
    FFmpeg::swscale
    FFmpeg::swresample
    Sodium::sodium
    OpenMP::OpenMP_CXX
    Qt6::Core
    Qt6::Widgets
)

# Enable Qt MOC only for GUI target
set_target_properties(media_storage_gui PROPERTIES 
    AUTOMOC ON 
    AUTOUIC ON
    AUTORCC OFF
)

# -------------------------------------------------------------------
# Compiler optimizations
# -------------------------------------------------------------------
if (MSVC)
    target_compile_options(media_storage PRIVATE
        $<$<CONFIG:Release>:/O2>
        /arch:AVX2
    )
    target_compile_options(media_storage_gui PRIVATE
        $<$<CONFIG:Release>:/O2>
        /arch:AVX2
    )
else ()
    target_compile_options(media_storage PRIVATE -march=native)
    if (CMAKE_SYSTEM_PROCESSOR MATCHES "x86_64|AMD64|i386")
        target_compile_options(media_storage_gui PRIVATE -O2 -mssse3)
    else ()
        target_compile_options(media_storage_gui PRIVATE -O2 -march=native)
    endif ()
endif ()