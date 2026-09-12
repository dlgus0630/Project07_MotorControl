# Edit this file, then run MATLAB/XSim checks for the changed source before build.
# internal: USB-only test plant. open_loop: real motor, fixed PWM for calibration.
# closed_loop: real motor PID, requires measured encoder normalization below.
set laplace_mode internal

# A-channel rising edges in 10 ms at the chosen 1.0-pu reference speed.
# 0 means UNKNOWN; it is not an encoder specification and blocks closed_loop.
# Use the SAME shaft for CPR and RPM. 12V/110RPM alone does not determine CPR.
set laplace_counts_full_scale 0
