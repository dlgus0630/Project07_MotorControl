#!/usr/bin/env python3
import json
from pathlib import Path

import numpy as np
from scipy import signal

from model import PID_CFG, pid_trace

ROOT = Path(__file__).resolve().parents[1]


def main():
    reference = np.loadtxt(ROOT / 'data/pid_reference.csv', delimiter=',', skiprows=1, dtype=int)
    actual = np.array(pid_trace())
    assert np.array_equal(actual, reference)
    assert int(actual[:, 4].min()) >= 0 and int(actual[:, 4].max()) <= 4096
    steady_error = int(actual[299, 1] - actual[299, 5])
    assert abs(steady_error) < 32

    time = np.arange(0, 1.5, .001)
    _, full = signal.step(signal.TransferFunction([.0027], [4e-7, .0004002, .0027]), T=time)
    _, reduced = signal.step(signal.TransferFunction([1], [.0002 / .00135, 1]), T=time)
    reduction_error = float(np.max(np.abs(full - reduced)))
    assert reduction_error < .02

    report = {'pid_samples': len(actual), 'pid_steady_error_q12': steady_error,
              'reduced_model_max_step_error_pu': reduction_error, 'pid_config': PID_CFG}
    output = ROOT / 'reports'
    output.mkdir(exist_ok=True)
    (output / 'offline_report.json').write_text(json.dumps(report, indent=2) + '\n')
    print(json.dumps(report, indent=2))
    print('OFFLINE CHECK PASS; MATLAB and XSim gates are unchanged.')


if __name__ == '__main__':
    main()

