@echo off
REM Will process the test files to generate a main proc and execute the generated file afterwards
odin run generate_test.odin && odin run tests/m_test_generated.odin -ignore-unknown-attributes