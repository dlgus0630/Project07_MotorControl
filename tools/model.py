"""Independent integer PID and first-order plant reference."""
import math

TAU = .0002 / (.0001 + .05 * .05 / 2)
PID_CFG = {'ts': .01, 'kp': round(.9 * 65536), 'ki_ts': round(6 * .01 * 65536),
           'kd_ts': round(.0015 / .01 * 65536), 'plant_a': round(math.exp(-.01 / TAU) * 65536)}


def sat(value, low, high):
    return max(low, min(high, int(value)))


def pid_step(reference, speed, integral, derivative, previous_speed):
    error = int(reference) - int(speed)
    derivative = (3 * derivative + int(speed) - previous_speed) >> 2
    proportional = (PID_CFG['kp'] * error) >> 16
    d_term = (PID_CFG['kd_ts'] * derivative) >> 16
    candidate = sat(integral + ((PID_CFG['ki_ts'] * error) >> 16), -4096, 4096)
    total = proportional + candidate - d_term
    if not ((total > 4096 and error > 0) or (total < 0 and error < 0)):
        integral = candidate
    return sat(proportional + integral - d_term, 0, 4096), integral, derivative, int(speed)


def pid_trace(count=1200):
    speed = integral = derivative = previous_speed = 0
    rows = []
    for index in range(count):
        reference = 0 if index < 20 else (2458 if index < 700 else 1229)
        load = 614 if 300 <= index < 500 else 0
        duty, integral, derivative, previous_speed = pid_step(
            reference, speed, integral, derivative, previous_speed)
        next_speed = (PID_CFG['plant_a'] * speed
                      + (65536 - PID_CFG['plant_a']) * max(duty - load, 0)) >> 16
        rows.append([index, reference, load, speed, duty, next_speed, integral, derivative])
        speed = next_speed
    return rows

