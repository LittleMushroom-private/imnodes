include(cmake/SystemLink.cmake)
include(cmake/LibFuzzer.cmake)
include(CMakeDependentOption)
include(CheckCXXCompilerFlag)


macro(imnodes_supports_sanitizers)
  if((CMAKE_CXX_COMPILER_ID MATCHES ".*Clang.*" OR CMAKE_CXX_COMPILER_ID MATCHES ".*GNU.*") AND NOT WIN32)
    set(SUPPORTS_UBSAN ON)
  else()
    set(SUPPORTS_UBSAN OFF)
  endif()

  if((CMAKE_CXX_COMPILER_ID MATCHES ".*Clang.*" OR CMAKE_CXX_COMPILER_ID MATCHES ".*GNU.*") AND WIN32)
    set(SUPPORTS_ASAN OFF)
  else()
    set(SUPPORTS_ASAN ON)
  endif()
endmacro()

macro(imnodes_setup_options)
  option(imnodes_ENABLE_HARDENING "Enable hardening" ON)
  option(imnodes_ENABLE_COVERAGE "Enable coverage reporting" OFF)
  cmake_dependent_option(
    imnodes_ENABLE_GLOBAL_HARDENING
    "Attempt to push hardening options to built dependencies"
    ON
    imnodes_ENABLE_HARDENING
    OFF)

  imnodes_supports_sanitizers()

  if(NOT PROJECT_IS_TOP_LEVEL OR imnodes_PACKAGING_MAINTAINER_MODE)
    option(imnodes_ENABLE_IPO "Enable IPO/LTO" OFF)
    option(imnodes_WARNINGS_AS_ERRORS "Treat Warnings As Errors" OFF)
    option(imnodes_ENABLE_USER_LINKER "Enable user-selected linker" OFF)
    option(imnodes_ENABLE_SANITIZER_ADDRESS "Enable address sanitizer" OFF)
    option(imnodes_ENABLE_SANITIZER_LEAK "Enable leak sanitizer" OFF)
    option(imnodes_ENABLE_SANITIZER_UNDEFINED "Enable undefined sanitizer" OFF)
    option(imnodes_ENABLE_SANITIZER_THREAD "Enable thread sanitizer" OFF)
    option(imnodes_ENABLE_SANITIZER_MEMORY "Enable memory sanitizer" OFF)
    option(imnodes_ENABLE_UNITY_BUILD "Enable unity builds" OFF)
    option(imnodes_ENABLE_CLANG_TIDY "Enable clang-tidy" OFF)
    option(imnodes_ENABLE_CPPCHECK "Enable cpp-check analysis" OFF)
    option(imnodes_ENABLE_PCH "Enable precompiled headers" OFF)
    option(imnodes_ENABLE_CACHE "Enable ccache" OFF)
  else()
    option(imnodes_ENABLE_IPO "Enable IPO/LTO" ON)
    # produce warning: optimization flag '-fno-fat-lto-objects' is not supported
    # option(imnodes_ENABLE_IPO "Enable IPO/LTO" OFF)
    # option(imnodes_WARNINGS_AS_ERRORS "Treat Warnings As Errors" ON)
    # suppress warning as error above
    option(imnodes_WARNINGS_AS_ERRORS "Treat Warnings As Errors" OFF)
    option(imnodes_ENABLE_USER_LINKER "Enable user-selected linker" OFF)
    option(imnodes_ENABLE_SANITIZER_ADDRESS "Enable address sanitizer" ${SUPPORTS_ASAN})
    option(imnodes_ENABLE_SANITIZER_LEAK "Enable leak sanitizer" OFF)
    option(imnodes_ENABLE_SANITIZER_UNDEFINED "Enable undefined sanitizer" ${SUPPORTS_UBSAN})
    option(imnodes_ENABLE_SANITIZER_THREAD "Enable thread sanitizer" OFF)
    option(imnodes_ENABLE_SANITIZER_MEMORY "Enable memory sanitizer" OFF)
    option(imnodes_ENABLE_UNITY_BUILD "Enable unity builds" OFF)
    option(imnodes_ENABLE_CLANG_TIDY "Enable clang-tidy" ON)
    option(imnodes_ENABLE_CPPCHECK "Enable cpp-check analysis" ON)
    option(imnodes_ENABLE_PCH "Enable precompiled headers" OFF)
    option(imnodes_ENABLE_CACHE "Enable ccache" ON)
  endif()

  if(NOT PROJECT_IS_TOP_LEVEL)
    mark_as_advanced(
      imnodes_ENABLE_IPO
      imnodes_WARNINGS_AS_ERRORS
      imnodes_ENABLE_USER_LINKER
      imnodes_ENABLE_SANITIZER_ADDRESS
      imnodes_ENABLE_SANITIZER_LEAK
      imnodes_ENABLE_SANITIZER_UNDEFINED
      imnodes_ENABLE_SANITIZER_THREAD
      imnodes_ENABLE_SANITIZER_MEMORY
      imnodes_ENABLE_UNITY_BUILD
      imnodes_ENABLE_CLANG_TIDY
      imnodes_ENABLE_CPPCHECK
      imnodes_ENABLE_COVERAGE
      imnodes_ENABLE_PCH
      imnodes_ENABLE_CACHE)
  endif()

  imnodes_check_libfuzzer_support(LIBFUZZER_SUPPORTED)
  if(LIBFUZZER_SUPPORTED AND (imnodes_ENABLE_SANITIZER_ADDRESS OR imnodes_ENABLE_SANITIZER_THREAD OR imnodes_ENABLE_SANITIZER_UNDEFINED))
    set(DEFAULT_FUZZER ON)
  else()
    set(DEFAULT_FUZZER OFF)
  endif()

  option(imnodes_BUILD_FUZZ_TESTS "Enable fuzz testing executable" ${DEFAULT_FUZZER})

endmacro()

macro(imnodes_global_options)
  if(imnodes_ENABLE_IPO)
    include(cmake/InterproceduralOptimization.cmake)
    imnodes_enable_ipo()
  endif()

  imnodes_supports_sanitizers()

  if(imnodes_ENABLE_HARDENING AND imnodes_ENABLE_GLOBAL_HARDENING)
    include(cmake/Hardening.cmake)
    if(NOT SUPPORTS_UBSAN 
       OR imnodes_ENABLE_SANITIZER_UNDEFINED
       OR imnodes_ENABLE_SANITIZER_ADDRESS
       OR imnodes_ENABLE_SANITIZER_THREAD
       OR imnodes_ENABLE_SANITIZER_LEAK)
      set(ENABLE_UBSAN_MINIMAL_RUNTIME FALSE)
    else()
      set(ENABLE_UBSAN_MINIMAL_RUNTIME TRUE)
    endif()
    message("${imnodes_ENABLE_HARDENING} ${ENABLE_UBSAN_MINIMAL_RUNTIME} ${imnodes_ENABLE_SANITIZER_UNDEFINED}")
    imnodes_enable_hardening(imnodes_options ON ${ENABLE_UBSAN_MINIMAL_RUNTIME})
  endif()
endmacro()

macro(imnodes_local_options)
  if(PROJECT_IS_TOP_LEVEL)
    include(cmake/StandardProjectSettings.cmake)
  endif()

  add_library(imnodes_warnings INTERFACE)
  add_library(imnodes_options INTERFACE)

  include(cmake/CompilerWarnings.cmake)
  imnodes_set_project_warnings(
    imnodes_warnings
    ${imnodes_WARNINGS_AS_ERRORS}
    ""
    ""
    ""
    "")

  if(imnodes_ENABLE_USER_LINKER)
    include(cmake/Linker.cmake)
    imnodes_configure_linker(imnodes_options)
  endif()

  include(cmake/Sanitizers.cmake)
  imnodes_enable_sanitizers(
    imnodes_options
    ${imnodes_ENABLE_SANITIZER_ADDRESS}
    ${imnodes_ENABLE_SANITIZER_LEAK}
    ${imnodes_ENABLE_SANITIZER_UNDEFINED}
    ${imnodes_ENABLE_SANITIZER_THREAD}
    ${imnodes_ENABLE_SANITIZER_MEMORY})

  set_target_properties(imnodes_options PROPERTIES UNITY_BUILD ${imnodes_ENABLE_UNITY_BUILD})

  if(imnodes_ENABLE_PCH)
    target_precompile_headers(
      imnodes_options
      INTERFACE
      <vector>
      <string>
      <utility>)
  endif()

  if(imnodes_ENABLE_CACHE)
    include(cmake/Cache.cmake)
    imnodes_enable_cache()
  endif()

  include(cmake/StaticAnalyzers.cmake)
  if(imnodes_ENABLE_CLANG_TIDY)
    imnodes_enable_clang_tidy(imnodes_options ${imnodes_WARNINGS_AS_ERRORS})
  endif()

  if(imnodes_ENABLE_CPPCHECK)
    imnodes_enable_cppcheck(${imnodes_WARNINGS_AS_ERRORS} "" # override cppcheck options
    )
  endif()

  if(imnodes_ENABLE_COVERAGE)
    include(cmake/Tests.cmake)
    imnodes_enable_coverage(imnodes_options)
  endif()

  if(imnodes_WARNINGS_AS_ERRORS)
    check_cxx_compiler_flag("-Wl,--fatal-warnings" LINKER_FATAL_WARNINGS)
    if(LINKER_FATAL_WARNINGS)
      # This is not working consistently, so disabling for now
      # target_link_options(imnodes_options INTERFACE -Wl,--fatal-warnings)
    endif()
  endif()

  if(imnodes_ENABLE_HARDENING AND NOT imnodes_ENABLE_GLOBAL_HARDENING)
    include(cmake/Hardening.cmake)
    if(NOT SUPPORTS_UBSAN 
       OR imnodes_ENABLE_SANITIZER_UNDEFINED
       OR imnodes_ENABLE_SANITIZER_ADDRESS
       OR imnodes_ENABLE_SANITIZER_THREAD
       OR imnodes_ENABLE_SANITIZER_LEAK)
      set(ENABLE_UBSAN_MINIMAL_RUNTIME FALSE)
    else()
      set(ENABLE_UBSAN_MINIMAL_RUNTIME TRUE)
    endif()
    imnodes_enable_hardening(imnodes_options OFF ${ENABLE_UBSAN_MINIMAL_RUNTIME})
  endif()

endmacro()
