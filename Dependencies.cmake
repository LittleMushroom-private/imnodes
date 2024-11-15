include(cmake/CPM.cmake)

# Done as a function so that updates to variables like
# CMAKE_CXX_FLAGS don't propagate out to other
# targets
function(imnodes_setup_dependencies)

  # For each dependency, see if it's
  # already been provided to us by a parent project

  if(NOT TARGET Catch2::Catch2WithMain)
    cpmaddpackage("gh:catchorg/Catch2@3.3.2")
  endif()

  if(NOT TARGET imgui)
    cpmaddpackage("gh:Curve/imgui-cmake#master")
    #cpmaddpackage("gh:ocornut/imgui@1.91.5")
    # add_library(imgui STATIC
    #   ${imgui_SOURCE_DIR}/imgui.cpp
    #   ${imgui_SOURCE_DIR}/imgui_draw.cpp
    #   ${imgui_SOURCE_DIR}/imgui_widgets.cpp
    #   ${imgui_SOURCE_DIR}/imgui_tables.cpp
    # )
    # target_include_directories(imgui INTERFACE ${imgui_SOURCE_DIR})
    # target_compile_definitions(imgui PUBLIC -DIMGUI_DISABLE_OBSOLETE_FUNCTIONS)
  endif()

  #https://github.com/kfsone/imguiwrap.git
  # if(NOT TARGET imguiwrap)
  #   cpmaddpackage("gh:kfsone/imguiwrap@1.2.2")
  # endif()

  # https://github.com/Nelarius/imnodes.git
  # if(NOT TARGET imnodes)
  #   cpmaddpackage("gh:Nelarius/imnodes#master") #Bad practice implemented due to lack of version maintainence of library
  # endif()
  
endfunction()
