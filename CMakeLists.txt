cmake_minimum_required(VERSION 3.21)

project(
  imnodes
  VERSION 0.0.1
  DESCRIPTION ""
  HOMEPAGE_URL "https://github.com/LittleMushroom-private/imnodes"
  LANGUAGES CXX C)

# Only set the cxx_standard if it is not set by someone else
if(NOT DEFINED CMAKE_CXX_STANDARD)
  set(CMAKE_CXX_STANDARD 20)
endif()

set(IMGUIWRAP_BACKEND "GL3W" CACHE STRING "Specify the imgui backend")

if(IMGUIWRAP_BACKEND STREQUAL "GL3W")
  add_compile_definitions(IMGUI_IMPL_OPENGL_LOADER_GL3W)
endif()

set(IMGUI_PLATFORM_BACKEND "glfw" CACHE STRING "Specify which imgui platform backend to use")
set(IMGUI_RENDERER_BACKEND "opengl3" CACHE STRING "Specify which imgui renderer backend to use")

# strongly encouraged to enable this globally to avoid conflicts between
# -Wpedantic being enabled and -std=c++20 and -std=gnu++20 for example
# when compiling with PCH enabled
set(CMAKE_CXX_EXTENSIONS OFF)

include(cmake/PreventInSourceBuilds.cmake)
include(ProjectOptions.cmake)

imnodes_setup_options()
imnodes_global_options() #

include(Dependencies.cmake)

imnodes_setup_dependencies()
imnodes_local_options()

# don't know if this should be set globally from here or not...
set(CMAKE_CXX_VISIBILITY_PRESET hidden)

set(GIT_SHA
  "Unknown"
  CACHE STRING "SHA this build was generated from")
string(
  SUBSTRING "${GIT_SHA}"
  0
  8
  GIT_SHORT_SHA)

target_compile_features(imnodes_options INTERFACE cxx_std_${CMAKE_CXX_STANDARD})

add_library(imnodes::imnodes_options ALIAS imnodes_options)
add_library(imnodes::imnodes_warnings ALIAS imnodes_warnings)

# add_library(imnodes::imnodes_options INTERFACE IMPORTED)
# add_library(imnodes::imnodes_warnings INTERFACE IMPORTED)

# configure files based on CMake configuration options
add_subdirectory(configured_files)

include(GenerateExportHeader)

add_library(imnodes src/imnodes.cpp)

add_library(imnodes::imnodes ALIAS imnodes)

# target_sources(imnodes PRIVATE
# imnodes.hpp
# imnodes_internal.hpp
# imnodes.cpp)
target_link_libraries(imnodes PRIVATE imnodes::imnodes_options imnodes::imnodes_warnings imgui)

# target_include_directories(imnodes ${WARNING_GUARD}
#   PRIVATE
#   ${CMAKE_CURRENT_SOURCE_DIR}/include/imnodes/imnodes.hpp
#   PUBLIC
#   $<BUILD_INTERFACE:${PROJECT_SOURCE_DIR}/include>
#   $<BUILD_INTERFACE:${PROJECT_BINARY_DIR}/include>)

target_compile_features(imnodes PUBLIC cxx_std_20)

set_target_properties(
  imnodes
  PROPERTIES VERSION ${PROJECT_VERSION}
  CXX_VISIBILITY_PRESET hidden
  VISIBILITY_INLINES_HIDDEN YES)

# generate_export_header(imnodes EXPORT_FILE_NAME ${PROJECT_BINARY_DIR}/include/imnodes/imnode_export.hpp)

if(NOT BUILD_SHARED_LIBS)
  target_compile_definitions(imnodes PUBLIC IMNODES_STATIC_DEFINE)
endif()

# Don't even look at tests if we're not top level
if(NOT PROJECT_IS_TOP_LEVEL)
  return()
endif()

# Adding the tests:
# include(CTest)

# if(BUILD_TESTING)
# message(AUTHOR_WARNING "Building Tests. Be sure to check out test/constexpr_tests.cpp for constexpr testing")
# add_subdirectory(test)
# endif()

# if(imnodes_BUILD_FUZZ_TESTS)
# message(AUTHOR_WARNING "Building Fuzz Tests, using fuzzing sanitizer https://www.llvm.org/docs/LibFuzzer.html")
# if (NOT imnodes_ENABLE_ADDRESS_SANITIZER AND NOT imnodes_ENABLE_THREAD_SANITIZER)
# message(WARNING "You need asan or tsan enabled for meaningful fuzz testing")
# endif()
# add_subdirectory(fuzz_test)

# endif()

# If MSVC is being used, and ASAN is enabled, we need to set the debugger environment
# so that it behaves well with MSVC's debugger, and we can run the target from visual studio
if(MSVC)
  get_all_installable_targets(all_targets)
  message("all_targets=${all_targets}")
  set_target_properties(${all_targets} PROPERTIES VS_DEBUGGER_ENVIRONMENT "PATH=$(VC_ExecutablePath_x64);%PATH%")
endif()

# set the startup project for the "play" button in MSVC
set_property(DIRECTORY PROPERTY VS_STARTUP_PROJECT standalone)

if(CMAKE_SKIP_INSTALL_RULES)
  return()
endif()

# include(cmake/PackageProject.cmake)

# # Add other targets that you want installed here, by default we just package the one executable
# # we know we want to ship
# imnodes_package_project(
# TARGETS
# imnodes
# imnodes_options
# imnodes_warnings
# # FIXME: this does not work! CK
# # PRIVATE_DEPENDENCIES_CONFIGURED project_options project_warnings
# )

# # Experience shows that explicit package naming can help make it easier to sort
# # out potential ABI related issues before they start, while helping you
# # track a build to a specific GIT SHA
# set(CPACK_PACKAGE_FILE_NAME
# "${CMAKE_PROJECT_NAME}-${CMAKE_PROJECT_VERSION}-${GIT_SHORT_SHA}-${CMAKE_SYSTEM_NAME}-${CMAKE_BUILD_TYPE}-${CMAKE_CXX_COMPILER_ID}-${CMAKE_CXX_COMPILER_VERSION}"
# )

# include(CPack)
