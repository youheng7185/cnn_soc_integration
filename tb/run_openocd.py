#!/usr/bin/env python3
"""Launch cv32e40p verilator sim and connect OpenOCD to it"""

import sys
import shlex
from subprocess import Popen, PIPE, STDOUT
from os import getenv

if __name__ == '__main__':

    # start the verilator simulation
    veri_proc = Popen(
        shlex.split('make run'),
        stdin=PIPE, stdout=PIPE, stderr=STDOUT,
        universal_newlines=True
    )

    # wait until SimJTAG prints its ready message
    for line in veri_proc.stdout:
        print(line, end='')
        if 'Listening on port' in line:
            print('Simulation ready — starting OpenOCD')
            break
        elif 'failed to bind socket' in line:
            print("Port busy. Try: killall Vcv32e40p_verilator_top", file=sys.stderr)
            sys.exit(1)

    # find openocd binary
    openocd = getenv('OPENOCD')
    if not openocd:
        riscv = getenv('RISCV')
        if riscv:
            openocd = riscv + '/bin/openocd'
    if not openocd:
        openocd = 'openocd'

    openocd_script = getenv('OPENOCD_SCRIPT', 'openocd_verilator.cfg')
    print(f"Using OpenOCD: {openocd}")
    print(f"Using script:  {openocd_script}")

    openocd_proc = Popen(
        shlex.split(f'{openocd} -f {openocd_script}'),
        stdin=PIPE, stdout=PIPE, stderr=STDOUT,
        universal_newlines=True
    )
    print('OpenOCD launched')

    # stream output — exit when done
    ret = 1
    for line in openocd_proc.stdout:
        print(line, end='')
        if 'ALL TESTS PASSED' in line:
            ret = 0
            break
        if 'Halted' in line:
            # interactive — just keep streaming
            pass

    # clean up both processes
    if not openocd_proc.poll():
        openocd_proc.kill()
    if not veri_proc.poll():
        veri_proc.kill()

    sys.exit(ret)