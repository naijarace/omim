project(generator_tests_support)

set(
  SRC
  restriction_helpers.cpp
  restriction_helpers.hpp
  test_feature.cpp
  test_feature.hpp
  test_mwm_builder.cpp
  test_mwm_builder.hpp
)

add_library(${PROJECT_NAME} ${SRC})
