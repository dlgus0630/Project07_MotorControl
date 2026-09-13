# Project07_MotorControl 작업 인수인계

마지막 갱신: 2026-09-13

이 문서는 현재 작업 상태와 다음 실행 순서를 한곳에 모은다. `artifacts`는 source digest 계산에서
제외되므로 진행 중 gate를 깨뜨리지 않고 갱신할 수 있다. 서로 충돌하는 메모가 있으면 이 문서와
실제 파일 및 보고서의 해시를 우선 확인한다.

## 1. 작업 운영 규칙

- 사용자는 시간이 부족하므로 한 번에 필요한 핵심 단계만 안내한다.
- 측정하지 않은 값을 실측, PASS 또는 완료로 기록하지 않는다.
- 실패를 숨기지 않고 원인, 수정 내용, 재검증 결과를 함께 남긴다.
- 소스 또는 동작 설정을 바꾸면 MATLAB/Simulink, 전체 XSim, Vivado 구현 순서로 다시 검증한다.
- 커밋과 push는 사용자가 직접 하며, 사용자가 해당 작업을 명시적으로 요청한 경우에만 대신 수행한다.
- Git 작성자는 `dlgus0630 <dlgus0630@naver.com>` 한 명만 사용한다.
- 공동 작성자 trailer나 특정 작성 도구를 나타내는 문구를 파일, 커밋 메시지, PR에 넣지 않는다.
- Project07은 `Project07_MotorControl`과 `Project07_VibrationNPU` 두 저장소로 구성한다.
- Basys3 Pure RTL 기준선을 보존하고 최종 Zybo SoC 통합은 `Project07_VibrationNPU`에서 진행한다.

### 작업 여유가 약 15% 이하일 때

새 빌드, 장시간 capture 또는 실물 시험을 시작하지 않는다. 다음 순서로 안전하게 넘긴다.

1. 실물 시험 중이면 사용자에게 `SW0 OFF -> PSU OUTPUT OFF` 순서를 즉시 안내한다.
2. 실행 중인 logger는 정상 종료를 기다리고, Vivado는 현재 단계가 곧 끝나면 완료까지 기다린다.
   장시간 멈췄다면 로그 경로와 마지막 출력부터 기록한 뒤 안전하게 중단한다.
3. 이 문서의 `현재 체크포인트`, 해시, PASS/FAIL, 미완료 항목과 바로 다음 명령을 갱신한다.
4. 실제로 생성된 CSV, bitstream, report만 기록한다. 예상 결과와 실측 결과를 구분한다.
5. `git status --short`를 기록하고 커밋이나 push 없이 종료한다.
6. 마지막 메시지에는 안전 상태, 마지막 성공 gate, 첫 번째 재개 명령을 짧게 적는다.

## 2. 목표와 현재 설계

목표는 Basys3에서 JGB37-520 모터의 PI 속도 제어를 구현하고, 내부 상태 telemetry와 반복 실험으로
성능을 수치화한 뒤 Zybo Z7-20의 PL/PS 공동설계로 확장하는 것이다.

```text
speed reference -> fixed-point PI -> saturation/anti-windup -> 20 kHz PWM
       ^                                                        |
       +---- hybrid encoder estimator <- C1 <- motor/L298N -----+

Basys3 USB-UART 115200 baud, 100 Hz
  -> sequence/reference/speed/duty/integral/flags/checksum
  -> PC CSV logger -> MATLAB step/disturbance/plant-ID analysis
```

현재 제어 설정:

- control rate: 100 Hz, `Ts=10 ms`
- PWM: 20 kHz
- PI: `Kp=0.9`, `Ki=6/s`, `Kd=0`
- Q16.16 계수와 64-bit 중간 연산
- conditional-integration anti-windup
- encoder stall fault: duty가 25%를 넘고 300 ms 동안 pulse가 없을 때 차단
- 보정값: C1 `988.427 rising edges/output revolution`
- RTL normalization: `ENCODER_COUNTS_FULL_SCALE=18`
- 동작 모드: `vivado/laplace_config.tcl`의 `closed_loop`

## 3. 안전 및 확정 배선

배선 변경은 Basys3 OFF와 PSU OUTPUT OFF에서만 한다. 시험을 멈출 때는 항상
`SW0 OFF -> PSU OUTPUT OFF` 순서를 사용한다. Scope ground clip은 공통 GND에만 연결하고
L298N OUT1/OUT2에는 연결하지 않는다.

| 대상 | 연결 |
|---|---|
| Motor 빨강 M1 | L298N OUT1 |
| Motor 흰색 M2 | L298N OUT2 |
| Encoder 파랑 VCC | Basys3 3.3 V |
| Encoder 검정 GND | 공통 GND |
| Encoder 초록 C1 | Basys3 JA4, FPGA G2 |
| Encoder 노랑 C2 | 현재 미사용, 절연 |
| Basys3 JA1, FPGA J1 | L298N ENA, ENA jumper 제거 |
| Basys3 JA2, FPGA L2 | L298N IN1 |
| Basys3 JA3, FPGA J2 | L298N IN2 |
| PSU +12 V | L298N +12V |
| PSU GND | L298N/Basys3/encoder 공통 GND |
| L298N 5V 단자 | 연결하지 않음 |

실물 시험 시작 조건은 PSU `12.0 V`, current limit `0.5 A`, `SW0 OFF`다. FPGA programming 뒤에도
SW0를 먼저 OFF로 인식시켜야 arm된다. 과전류, CC 진입, 정지, 냄새 또는 과열이 있으면 즉시 종료한다.

## 4. 확정된 기준선 결과

### PI와 하드웨어

- Basys3 JA1: 20 kHz, 약 25%, 0~3.3 V PWM PASS
- JA2/JA3: 정방향 HIGH/LOW PASS
- L298N open-loop: 12.0 V, 약 0.07 A, 연속 회전 PASS
- Encoder C1 전기 신호와 JA4 FPGA 입력 PASS
- 최종 C1 CPR: `988.427 pulse/output revolution`
- SW1 목표 13.66 RPM: 기계 실측 13.39 RPM, 목표 오차 -1.94%, 0.08 A, fault 없음
- SW2 목표 27.32 RPM: 기계 실측 27.03 RPM, 목표 오차 -1.06%, 0.11 A, fault 없음
- 기준 PI bitstream: `artifacts/laplace_pi_closed_loop.bit`
- 기준 PI bitstream SHA-256:
  `a21821031006dc9a44cc4a9703e4d758fd2462ef50669c21680d1d4955edaa37`

### Window-count telemetry 기준선

현재 Basys3에 마지막으로 program한 파일은 아래 기존 estimator telemetry bitstream이다.

- 파일: `artifacts/laplace_pi_telemetry.bit`
- SHA-256: `9dbdcf2f58c2a6f95ea6033a27bef028cf946ae59604e152bed73e668ddbfb95`
- programming: Basys3 `xc7a35t_0` PASS
- 이 bitstream은 새 hybrid estimator를 포함하지 않는다.

기존 estimator의 27.32 -> 40.97 RPM step 3회 결과:

| Metric | Mean | Std | Min | Max |
|---|---:|---:|---:|---:|
| Rise time [s] | 0.3267 | 0.0153 | 0.310 | 0.340 |
| Overshoot [%] | 7.8666 | 2.5141 | 6.4092 | 10.7696 |
| Settling time [s] | 8.4000 | 3.2453 | 4.750 | 10.960 |
| Steady RPM | 40.7362 | 0.0030 | 40.7332 | 40.7392 |
| Steady error [%] | -0.5808 | 0.0073 | -0.5880 | -0.5735 |

CSV는 `artifacts/experiments/step_trial_01.csv`부터 `step_trial_03.csv`, 집계는
`artifacts/experiments/baseline_step_summary.csv`에 있다. 세 capture 모두 dropped frame 0,
bad checksum 0, fault 0이다.

## 5. 현재 개발분: hybrid encoder estimator

저속에서 10 ms window-count의 1-count 양자화를 줄이기 위해 reciprocal pulse-period와 window-count를
결합했다.

변경 및 추가 파일:

- `laplace/rtl/unsigned_divider.v`: 32-cycle iterative unsigned divider
- `laplace/rtl/encoder_speed_hybrid.v`: 저속 reciprocal, 고속 window-count, 100 ms timeout
- `laplace/rtl/laplace_basys3_top.v`: hybrid estimator 연결
- `laplace/tb/tb_encoder_hybrid.v`: reciprocal 저속과 timeout self-check
- `vivado/run_simulations.tcl`: 전체 7개 testbench에 hybrid test 추가
- `matlab/ANALYZE_TELEMETRY.m`: raw/filtered steady-state 표준편차 출력
- `matlab/ANALYZE_TRIALS.m`: 반복 trial jitter 집계

isolated `tb_encoder_hybrid`는 PASS했다. 첫 simulation에서는 pulse edge에서 `period_count`를 reset한 값이
divider 입력으로 전달되는 버그를 찾았다. `period_divisor` latch를 추가해 수정했고 isolated test를
다시 통과했다. 전체 XSim 7개 regression과 구현은 아직 완료로 기록하면 안 된다.

## 6. 현재 체크포인트

현재 source digest:

```text
f8ed5101583122813831489f01957dff36ff62414e47bb37050f83dac7f952c2
```

MATLAB Online용 package:

- `artifacts/p07_hybrid_v1.zip`
- SHA-256: `fb9ca9c141ed76e7a45183818e9512ce363b14fd99683e6533c6e8f5d386a98e`

사용자가 내려받은 결과:

- 원본: `/home/dlgus0630/Downloads/matlab_results (9).zip`
- SHA-256: `81c6aee65bc69cbeb48580b4229d13d3ee354a61e2935d9f2d11c73a87997f3a`
- `reports/matlab.pass`가 현재 source digest와 정확히 일치
- `reports/analysis_self_test.txt`: `ANALYSIS SELF TEST PASS`
- MATLAB/Simulink: PASS

이 문서 작성 시점의 다음 gate 상태:

- [x] hybrid isolated XSim
- [x] hybrid MATLAB/Simulink 및 analysis self-test
- [x] 첨부 MATLAB 결과를 현재 `reports/`에 반영하고 gate 확인
- [x] 전체 XSim 7개 regression
- [x] Vivado synthesis/implementation/timing/DRC: post-route 최적화 후 timing closure
- [x] hybrid bitstream 보관 및 SHA-256 기록
- [x] Basys3 programming (JTAG `210183BB794FA`, `xc7a35t_0`, 2026-09-13 16:02 KST 최초 programming,
  이후 hysteresis 수정 bitstream으로 16:46 KST 재programming, DONE=HIGH 확인)
- [x] hybrid step 3회 capture 및 기준선 비교 — 최초 bitstream(SHA-256 `3e6fc6bb...`)에서
  raw `measured_q12`가 `1820`으로 튀는 재현 가능한 결함을 발견해 `HIGH/LOW_COUNT_THRESHOLD`
  히스테리시스로 수정(SHA-256 `b7e7599c...`), MATLAB/XSim/Vivado 재검증 후 재programming하고
  3회 재측정 완료. 정착시간 8.40±3.25 s(기존) → 0.82±0.05 s(수정 후)로 개선, 글리치 재발 0회.
  자세한 원인·수정·수치는 [README.md](../README.md)의 "트러블슈팅" 절 참고.

첫 hybrid 구현 시 synthesis는 오류 0, route 및 DRC는 오류 0이었지만 최종 timing은 setup WNS
`-0.113 ns`, TNS `-0.594 ns`, hold WHS `+0.122 ns`였다. 위반 경로는
`controller/i_candidate1/CLK -> controller/candidate_reg[25]/D`이며 64-bit 적분 후보 계산 경로다.
빌드 스크립트가 bitstream 작성을 차단했다. 이후 같은 routed checkpoint에 `phys_opt_design
-directive AggressiveExplore`와 `route_design -directive AggressiveExplore`를 적용해 setup WNS
`+0.033 ns`, hold WHS `+0.122 ns`, DRC Error 0으로 timing closure했다. 재현 Tcl은
`artifacts/postroute_hybrid_timing.tcl`이다. `reports/laplace/laplace.bit`는 이번 빌드 결과가 아니라
이전 telemetry bitstream과 같은 SHA-256 `9dbdcf...fb95`를 가진 잔존 파일이므로 hybrid용으로 사용하면
안 된다.

최종 hybrid 구현 결과:

```text
setup WNS  = +0.033 ns
hold WHS   = +0.122 ns
DRC Errors = 0
LUT        = 742 / 20800 (3.57%)
FF         = 790 / 41600 (1.90%)
DSP        = 4 / 90 (4.44%)
BRAM       = 0
```

최종 보관 파일:

- `artifacts/laplace_pi_hybrid_telemetry.bit`
- bitstream SHA-256: `3e6fc6bb7941510cfc107d037da6d9a33548c9fbf61f7fb60f7b95874761791e`
- timing report SHA-256: `bc954f2b37745b7f79a5aa976d83dd215e11b2e5035055b0f5cdad607113bd07`
- DRC report SHA-256: `54b42644138f607a3809c212520ba7c578ce78e825033042f75868a9f89d81f2`
- utilization report SHA-256: `59a11c03631ade7a6a24fb0afb6d7d59cb68c3e91afe347a05d9e94f045f9279`

DRC에는 DSP pipelining과 배치 관련 Warning 12개가 있으나 Error는 0이고 timing 제약은 모두 충족했다.
새 hybrid bitstream은 아직 Basys3에 program하거나 실물 측정하지 않았다.

## 7. 바로 재개할 명령

작업 위치:

```bash
cd /home/dlgus0630/Downloads/fpga_fourier_pid_v4/Project07_MotorControl
```

### A. MATLAB 결과 반영과 gate 확인

```bash
rm -rf /tmp/p07_matlab_results_9
unzip '/home/dlgus0630/Downloads/matlab_results (9).zip' -d /tmp/p07_matlab_results_9
cp /tmp/p07_matlab_results_9/reports/{matlab.pass,matlab_reference.mat,laplace_pid_closed_loop.slx,analysis_self_test.txt} reports/
python3 tools/gates.py check matlab
```

### B. 전체 XSim 7개

```bash
env VIVADO=/tools/Xilinx/Vivado/2024.2/bin/vivado python3 tools/run.py sim
```

성공 시 `reports/sim.pass`가 생기고 로그에 아래 7개가 모두 PASS여야 한다.

```text
tb_pid_loop
tb_pid_limits
tb_pwm_encoder
tb_encoder_hybrid
tb_uart_telemetry
tb_laplace_top
tb_laplace_motor
```

XSim이 `unexpected exception`으로 종료됐지만 개별 test의 RTL 오류가 없다면 환경 문제 가능성이 있다.
같은 명령을 일반 터미널에서 한 번 다시 실행하고 각 `reports/tb_*.log`를 확인한다.

### C. Vivado 구현 재현

XSim이 모두 PASS한 뒤에만 실행한다.

```bash
env VIVADO=/tools/Xilinx/Vivado/2024.2/bin/vivado python3 tools/run.py build
```

현재 배치에서는 기본 route가 setup WNS -0.113 ns로 멈춘다. 이 상태에서 아래 명령을 실행하면
검증용 post-route Tcl이 timing을 다시 최적화하고, timing/DRC 통과 후에만 bitstream을 쓴다.

```bash
/tools/Xilinx/Vivado/2024.2/bin/vivado -mode batch -nojournal \
  -log reports/vivado_hybrid_postroute.log \
  -source artifacts/postroute_hybrid_timing.tcl
```

확인 항목:

- setup WNS > 0
- hold WHS > 0
- DRC Error 0
- LUT, FF, DSP, BRAM 기록
- 생성 bitstream SHA-256 기록

새 파일은 기존 telemetry 파일을 덮어쓰지 말고 다음 이름으로 보관한다. 현재는 이미 보관 완료됐다.

```text
artifacts/laplace_pi_hybrid_telemetry.bit
artifacts/laplace_pi_hybrid_telemetry_timing.rpt
artifacts/laplace_pi_hybrid_telemetry_drc.rpt
artifacts/laplace_pi_hybrid_telemetry_utilization.rpt
```

## 8. Hybrid 실물 비교 절차

programming 전에 `SW0 OFF`, `PSU OUTPUT OFF`를 확인한다. 새 bitstream을 올린 뒤 PSU를 12.0 V,
0.5 A limit로 두고 SW2만 ON한 상태에서 마지막에 SW0를 ON한다. 27.32 RPM 근처에서 안정화한 뒤
30초 capture 중 표식이 나오면 SW1을 ON해 목표를 40.97 RPM으로 바꾼다.

```bash
python3 tools/capture_telemetry.py --port /dev/ttyUSB1 --duration 30 --mark-after 8 \
  --output artifacts/experiments/hybrid_step_trial_01.csv
```

같은 방식으로 `hybrid_step_trial_02.csv`, `hybrid_step_trial_03.csv`까지 세 번 측정한다. 실제 장치명은
`ls -l /dev/ttyUSB*`로 먼저 확인한다. 매 trial 종료 뒤 `SW0 OFF -> PSU OUTPUT OFF`로 정지한다.

비교할 핵심 지표:

- 10~90% rise time
- overshoot
- 2% settling time
- steady-state error
- raw steady-state RPM 표준편차
- filtered steady-state RPM 표준편차
- dropped frames, bad checksums, fault 발생 여부

hybrid가 기준선보다 jitter와 settling 분산을 실제로 줄였을 때만 개선으로 판정한다. 성능이 악화되면
전환 threshold, reciprocal filter 지연과 period 업데이트 시점을 로그로 분석한다.

## 9. Hybrid 비교 뒤 확장 순서

1. SW2 목표에서 `12 V -> 9 V -> 12 V` 전원 외란을 3회 기록해 최대 편차와 복원시간을 비교한다.
2. Open-loop 다단 duty CSV로 1차+dead-time 모델을 식별하고 60/20/20 train/validation/test 결과를 낸다.
3. 식별 모델의 PI 후보와 현재 PI를 MATLAB, XSim, 동일 실물 step에서 비교한다.
4. Encoder C2를 추가해 quadrature 방향 및 illegal transition을 검증한다.

5번은 별도의 MotorControl Zybo 복제 프로젝트로 만들지 않는다. Basys3 Pure RTL 구현과 실측 결과는
이 저장소의 독립 기준선으로 보존하고, 검증된 PI·hybrid encoder estimator·anti-windup·보호 FSM을
`Project07_VibrationNPU`의 최종 Zybo 통합 시스템에서 재사용한다. 최종 시스템은 실제 진동을
FFT/NPU로 분류하고 이상 판정이 모터 제한 또는 latched stop으로 이어지는 경로를 실측한다.

AXI4-Lite, telemetry FIFO/interrupt와 PS heartbeat를 두 저장소에 중복 구현하지 않는다. 통합에 필요한
최소 register/status와 안전 경로를 `Project07_VibrationNPU`에 두고, 이 저장소에서는 Basys3 제어
기준선과 제어 알고리즘의 검증 증거를 유지한다.

Zybo 단계에서도 100 Hz 제어, PWM, encoder와 보호 기능은 PL이 소유해야 한다. PS가 멈추거나 heartbeat가
끊겨도 PL이 motor output을 차단하도록 한다. AXI register는 version/status/reference/Kp/Ki/command,
fault cause, sample counter와 telemetry overflow/drop counter를 포함한다.

## 10. 저장소 상태와 종료 전 확인

- branch: `main`
- 현재 완료된 hybrid estimator 기준선과 실측 결과는 README 및 이 문서에 반영됐다.
- 명시적인 사용자 요청 없이 `git reset --hard`, 대량 삭제, commit 또는 push를 실행하지 않는다.

종료 전 최소 기록:

```bash
git status --short
python3 - <<'PY'
from tools.gates import digest
print(digest())
PY
sha256sum artifacts/laplace_pi_hybrid_telemetry.bit 2>/dev/null || true
```

마지막 전달 형식:

```text
안전 상태: SW0 OFF / PSU OUTPUT OFF
마지막 성공 gate: ...
현재 source digest: ...
생성된 핵심 파일과 SHA-256: ...
실측 완료 결과: ...
아직 실행하지 않은 항목: ...
첫 재개 명령: ...
```
