#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BUILD_DIR="${SCRIPT_DIR}/build"
SPIKE_LOG_DIR="${BUILD_DIR}/spike_logs"
VERILATOR_LOG_DIR="${BUILD_DIR}/verilator_logs"
COMPARE_DIR="${BUILD_DIR}/compare_results"

SPIKE_ISA="rv32imc_zicsr"
SPIKE_PRIV="mu"
SPIKE_MEM="0x80000000:0x10000,0x10000000:0x10000"
SPIKE_INSTRUCTIONS=50000

MAX_CYCLES=1000000

SPIKE="${SPIKE:-spike}"
RISCV_PREFIX="${RISCV_PREFIX:-riscv32-unknown-elf-}"
VERILATOR_SIM="${VERILATOR_SIM:-${SCRIPT_DIR}/../obj_dir/Vcv32e40p_verilator_top}"
COMPARE_TOOL="${COMPARE_TOOL:-${BUILD_DIR}/compare_trace}"
WORK_DIR="${SCRIPT_DIR}/.."

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

mkdir -p "${SPIKE_LOG_DIR}" "${VERILATOR_LOG_DIR}" "${COMPARE_DIR}"

print_header() {
    echo ""
    echo "========================================"
    echo "  $1"
    echo "========================================"
}

print_result() {
    local name="$1"
    local result="$2"
    if [ "$result" = "PASS" ]; then
        echo -e "  ${GREEN}[PASS]${NC} ${name}"
    elif [ "$result" = "FAIL" ]; then
        echo -e "  ${RED}[FAIL]${NC} ${name}"
    else
        echo -e "  ${YELLOW}[SKIP]${NC} ${name} (${result})"
    fi
}

run_spike_test() {
    local elf_file="$1"
    local test_name="$(basename "$elf_file" _soc.elf)"
    local spike_log="${SPIKE_LOG_DIR}/${test_name}_spike.log"

    echo "  Running Spike: ${test_name}"

    ${SPIKE} \
        --isa=${SPIKE_ISA} \
        --priv=${SPIKE_PRIV} \
        --disable-dtb \
        -m${SPIKE_MEM} \
        --pc=0x80000000 \
        --instructions=${SPIKE_INSTRUCTIONS} \
        --log-commits \
        --log=${spike_log} \
        ${elf_file} 2>/dev/null || true

    if [ ! -s "${spike_log}" ]; then
        echo "  WARNING: Spike produced empty log for ${test_name}"
        return 1
    fi

    local lines=$(wc -l < "${spike_log}")
    echo "  Spike: ${lines} lines"
    return 0
}

run_verilator_test() {
    local hex_file="$1"
    local byte_hex_file="${hex_file/_clean.hex/_clean_byte.hex}"
    local test_name="$(basename "$hex_file" _soc_clean.hex)"
    local verilator_log="${VERILATOR_LOG_DIR}/${test_name}_verilator.log"
    local firmware_hex="${WORK_DIR}/cnn_soc_c_project/build/firmware_clean.hex"
    local firmware_byte="${WORK_DIR}/cnn_soc_c_project/build/firmware_clean_byte.hex"

    echo "  Running Verilator: ${test_name}"

    cp "${hex_file}" "${firmware_hex}"
    if [ -f "${byte_hex_file}" ]; then
        cp "${byte_hex_file}" "${firmware_byte}"
    else
        hexdump -v -e '1/1 "%02x\n"' "$(dirname "$hex_file")/${test_name}_soc.bin" > "${firmware_byte}" 2>/dev/null || true
    fi

    if [ -x "${VERILATOR_SIM}" ]; then
        rm -f trace_core_00000000.log
        "${VERILATOR_SIM}" +maxcycles ${MAX_CYCLES} > /dev/null 2>&1 || true
    fi

    if [ -f "trace_core_00000000.log" ]; then
        mv trace_core_00000000.log "${verilator_log}"
    fi

    if [ ! -s "${verilator_log}" ]; then
        echo "  WARNING: Verilator produced no log for ${test_name}"
        return 1
    fi

    local lines=$(wc -l < "${verilator_log}")
    echo "  Verilator: ${lines} lines"
    return 0
}

compare_traces() {
    local test_name="$1"
    local verilator_log="${VERILATOR_LOG_DIR}/${test_name}_verilator.log"
    local spike_log="${SPIKE_LOG_DIR}/${test_name}_spike.log"
    local compare_out="${COMPARE_DIR}/${test_name}_result.txt"

    echo "  Comparing: ${test_name}"

    if [ ! -f "${verilator_log}" ] || [ ! -f "${spike_log}" ]; then
        print_result "${test_name}" "MISSING"
        return 1
    fi

    if [ ! -x "${COMPARE_TOOL}" ]; then
        echo "  Building compare tool..."
        gcc -O2 -o "${COMPARE_TOOL}" "${SCRIPT_DIR}/tools/compare_trace.c"
    fi

    ulimit -s unlimited

    "${COMPARE_TOOL}" "${verilator_log}" "${spike_log}" > "${compare_out}" 2>&1
    local ret=$?

    if [ $ret -eq 0 ]; then
        print_result "${test_name}" "PASS"
    else
        print_result "${test_name}" "FAIL"
        echo "  Details in: ${compare_out}"
    fi

    return $ret
}

build_all_tests() {
    print_header "Building all tests"
    make -C "${SCRIPT_DIR}" all
}

run_all_spike() {
    print_header "Running Spike-only tests"

    for elf in "${BUILD_DIR}"/*_soc.elf; do
        if [ ! -f "${elf}" ]; then continue; fi
        run_spike_test "${elf}" || true
    done

    echo ""
    echo "Spike logs saved to: ${SPIKE_LOG_DIR}"
}

run_verilator_tests() {
    print_header "Running Verilator tests"

    for hex in "${BUILD_DIR}"/*_soc_clean.hex; do
        if [ ! -f "${hex}" ]; then continue; fi
        run_verilator_test "${hex}" || true
    done

    echo ""
    echo "Verilator logs saved to: ${VERILATOR_LOG_DIR}"
}

run_compare_all() {
    local pass_count=0
    local fail_count=0
    local skip_count=0

    print_header "Comparing traces"

    for elf in "${BUILD_DIR}"/*_soc.elf; do
        if [ ! -f "${elf}" ]; then continue; fi
        local test_name="$(basename "$elf" _soc.elf)"

        if compare_traces "${test_name}"; then
            pass_count=$((pass_count + 1))
        else
            local compare_out="${COMPARE_DIR}/${test_name}_result.txt"
            if [ -f "${compare_out}" ] && grep -q "NO COMPARABLE" "${compare_out}"; then
                skip_count=$((skip_count + 1))
            else
                fail_count=$((fail_count + 1))
            fi
        fi
    done

    print_header "Summary"
    echo "  PASS:  ${pass_count}"
    echo "  FAIL:  ${fail_count}"
    echo "  SKIP:  ${skip_count}"
    echo ""

    if [ ${fail_count} -eq 0 ]; then
        echo -e "${GREEN}ALL TESTS PASSED${NC}"
        return 0
    else
        echo -e "${RED}SOME TESTS FAILED${NC}"
        return 1
    fi
}

case "${1:-spike}" in
    build)
        build_all_tests
        ;;
    spike)
        build_all_tests
        run_all_spike
        ;;
    verilator)
        build_all_tests
        run_verilator_tests
        ;;
    compare)
        run_compare_all
        ;;
    all)
        build_all_tests
        run_all_spike
        run_verilator_tests
        run_compare_all
        ;;
    clean)
        make -C "${SCRIPT_DIR}" clean
        rm -rf "${SPIKE_LOG_DIR}" "${VERILATOR_LOG_DIR}" "${COMPARE_DIR}"
        ;;
    *)
        echo "Usage: $0 {build|spike|verilator|compare|all|clean}"
        echo ""
        echo "  build      - Build all test ELF files and hex files"
        echo "  spike      - Build and run Spike simulation"
        echo "  verilator  - Build and run Verilator simulation"
        echo "  compare    - Compare Spike and Verilator traces"
        echo "  all        - Run complete pipeline (spike + verilator + compare)"
        echo "  clean      - Clean all build artifacts"
        ;;
esac