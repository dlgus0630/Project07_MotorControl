# Project07_MotorControl

Basys3에서 JGB37-520 엔코더 DC 기어모터의 속도를 제어하고 정량적으로 검증하는 FPGA 프로젝트다. MATLAB에서
연속시간 모터 모델과 제어기를 설계하고, 이를 10 ms 주기의 고정소수점 제어기와 20 kHz PWM으로
변환해 Verilog-2001 RTL로 구현한다. MicroBlaze와 HDL Coder는 사용하지 않았다.

```text
speed reference -> fixed-point controller -> saturation -> 20 kHz PWM -> L298N -> motor
                         ^                                           |
                         +--------- Hall encoder C1 feedback --------+
```

## 구현 내용

- Digilent Basys3, Xilinx Artix-7
- JGB37-520, DC 12 V, 110 RPM, Hall encoder 내장 기어모터
- L298N H-bridge motor driver
- 100 Hz 고정소수점 PI와 20 kHz PWM
- Q16.16 제어기 계수와 64-bit 중간 연산
- PWM 출력 saturation과 conditional integration anti-windup
- C1 window-count와 reciprocal-period를 결합한 저속 속도 측정
- 내부 test plant, 외부 open-loop, 외부 closed-loop 모드
- arm 절차, 즉시 출력 차단 및 encoder stall fault
- 100 Hz USB-UART 내부상태 telemetry와 checksum/sequence 검증
- MATLAB step response, 외란 복원 및 train/validation/test 모터 식별

현재 실물 closed-loop 소스는 `Kp=0.9`, `Ki=6/s`, `Kd=0`인 PI다. Encoder 양자화에 민감한
D항은 첫 실물 시험에서 제외했고 derivative state는 향후 PID 비교를 위해 유지한다. 출력 포화 시
같은 방향의 적분 갱신을 막는 conditional-integration anti-windup을 적용했다.

## 현재 진행 상태

| 단계 | 결과 |
|---|---|
| MATLAB/Simulink 기준 모델 | CPR 988.4 보정 PI PASS |
| XSim 기준선 | 5개 testbench PASS |
| UART telemetry 단위시험 | 16-byte payload/checksum XSim PASS, 전체 regression 대기 |
| Vivado 2024.2 open-loop | Timing PASS, DRC Error 0 |
| Basys3 PWM/방향 출력 | PASS |
| L298N ENA 전달 | PASS |
| 실제 open-loop 모터 구동 | PASS |
| Encoder C1 전기 신호 | PASS |
| Encoder C1 FPGA 입력 | PASS |
| C1 CPR 및 RPM 환산 | 반복 실측 완료: 약 988.4 pulse/rev |
| PI closed-loop 구동 | PASS |
| 목표 속도 추종 | 13.66 RPM 및 27.32 RPM 두 운전점 PASS |

Open-loop 구현 결과는 setup slack `+3.142 ns`, hold slack `+0.122 ns`, LUT 84, FF 180,
DSP 1, BRAM 0이다. 최종 PI closed-loop 구현은 setup slack `+0.060 ns`, hold slack `+0.122 ns`,
DRC Error 0, LUT 450, FF 416, DSP 4, BRAM 0을 기록했다.

## 배선

### 모터와 encoder

| 선 색상 | 기능 | 연결 |
|---|---|---|
| 빨강 | Motor M1 | L298N OUT1 |
| 흰색 | Motor M2 | L298N OUT2 |
| 파랑 | Encoder VCC | Basys3 3.3 V |
| 검정 | Encoder GND | 공통 GND |
| 초록 | Encoder C1 | Basys3 JA4 |
| 노랑 | Encoder C2 | 현재 미사용, 절연 |

### Basys3, L298N 및 전원

| 신호 | FPGA 핀 | 연결 |
|---|---|---|
| JA1 `motor_pwm` | J1 | L298N ENA, ENA 점퍼 제거 |
| JA2 `motor_in1` | L2 | L298N IN1 |
| JA3 `motor_in2` | J2 | L298N IN2 |
| JA4 `encoder_a` | G2 | Encoder C1 |
| USB-UART `uart_tx` | A18 | Basys3 FTDI Rx, 115200 baud |
| GND | - | L298N, encoder, PSU 공통 GND |
| PSU +12 V | - | L298N +12V |

L298N의 `5V` 단자에는 외부 전원을 연결하지 않는다. 12 V는 L298N 모터 전원에만 연결하며
Basys3와 encoder에 연결하지 않는다.

## 스위치

- `SW0`: motor arm/enable. FPGA reset 또는 programming 뒤 OFF를 확인한 다음 ON해야 한다.
- `SW3:SW1`: 0~87.5% 범위의 open-loop duty 또는 closed-loop speed reference
- `SW4`: 외부 모드에서 C1 상승 에지의 1초 누적값을 LED에 이진수로 표시
- `BTNC`: reset 및 즉시 motor output 차단

25% open-loop 시험 설정은 `SW3=OFF`, `SW2=ON`, `SW1=OFF`이며 마지막에 `SW0`을 ON한다.

## 실물 측정 결과

| 시험 | 조건 | 결과 |
|---|---|---|
| 모터 단독 구동 | DC 3.0 V | CW 회전, 약 0.09~0.11 A |
| Basys3 JA1 | SW2+SW0 ON | 20 kHz, 약 25%, 약 0~3.3 V |
| Basys3 JA2/JA3 | 정방향 | 약 3.39 V / 약 0 V |
| L298N open-loop | PSU 12.0 V, 25% PWM | 저속 연속 회전, 약 0.07 A |
| Encoder C1 | 위 open-loop 조건 | 약 0~3.3 V, 90.75 Hz |
| 출력축 속도 | 10회전 85.0 s | 약 7.06 RPM |
| 첫 C1 환산값 | open-loop 조건 | 약 771.4, 폐루프에서 재현되지 않아 폐기 |
| PI 폐루프 보정 1 | C1 172.4 Hz, 출력축 10회전 57.30 s | 약 987.9 pulse/rev |
| PI 폐루프 보정 2 | C1 172.4 Hz, 출력축 5회전 28.70 s | 약 989.6 pulse/rev |
| 최종 C1 환산값 | 두 폐루프 측정 합산 | 약 988.4 rising edges/output revolution |
| PI 목표 1 | 목표 225 Hz, 약 13.66 RPM | 221.2 Hz, 5회전 22.40 s, 약 0.08 A, fault 없음 |
| PI 목표 2 | 목표 450 Hz, 약 27.32 RPM | 446.4 Hz, 5회전 11.10 s, 약 0.11 A, fault 없음 |

초기 open-loop CPR 771.4는 반복 측정에서 재현되지 않아 최종 보정에 사용하지 않는다. 폐루프 안정
상태에서 C1 주파수와 출력축 회전시간을 두 번 동시에 측정했으며 두 CPR 결과는 약 0.17% 차이다.

```text
C1 CPR 1 = 172.4 * 57.30 / 10 = 987.852 pulse/rev
C1 CPR 2 = 172.4 * 28.70 / 5 = 989.576 pulse/rev
C1 CPR combined = 172.4 * 86.00 / 15 = 988.427 pulse/rev
```

정격 110 RPM을 1.0 pu로 정하면 10 ms 동안의 C1 pulse 수는 다음과 같다.

```text
counts_full_scale = 988.427 * 110 / 60 * 0.01 = 18.12
ENCODER_COUNTS_FULL_SCALE = 18
```

정수값 18이 나타내는 실제 full-scale은 약 109.3 RPM이다. Closed-loop speed reference는
SW1부터 각각 약 13.66, 27.32, 40.97, 54.63, 68.29, 81.95, 95.61 RPM이다.

최종 폐루프 실측은 다음과 같다.

| 설정 | 목표 | Encoder 실측 | 기계 실측 | 기계 속도 오차 |
|---|---|---|---|---|
| SW1 | 225 Hz, 13.66 RPM | 221.2 Hz, 13.43 RPM | 5회전 22.40 s, 13.39 RPM | -1.94% |
| SW2 | 450 Hz, 27.32 RPM | 446.4 Hz, 27.10 RPM | 5회전 11.10 s, 27.03 RPM | -1.06% |

두 운전점 모두 encoder 환산 속도와 출력축 실측 속도가 약 0.3% 이내로 일치했고 `LD1` fault는
발생하지 않았다.

## 트러블슈팅

### Hybrid encoder estimator의 1-sample 속도 glitch (해결됨)

**증상**: hybrid reciprocal/window-count estimator telemetry에서 27.32→40.97 RPM step 응답의
정상상태(40.9 RPM 부근) 도중 raw `measured_q12`가 정확히 `1820`(48.55 RPM)으로 튀는 1-sample
spike가 30초 측정당 약 3회(10.61 s, 16.70 s, 22.16 s) 반복 관측됐다. 매번 정확히 같은 raw 값이라
노이즈가 아니라 결정론적 로직 문제였다.

**원인**: `laplace/rtl/encoder_speed_hybrid.v`가 `window_total>=HIGH_COUNT_THRESHOLD`(당시 8)를
매 `sample_tick`마다 새로 평가해 reciprocal-period 결과 대신 window-count 결과를 즉시 채택했다.
40.97 RPM, CPR 988.427에서 10 ms window당 기대 pulse 수는 약 6.75개인데, threshold(8)가 평균보다
겨우 1.25 count 위에 있어 pulse 타이밍만으로도 가끔 window당 8개에 도달했다. 그 순간
`window_speed = (8 * RECIP_Q12) >> 12 = (8 * 932068) >> 12 = 1820`이 그대로 출력됐고, 다음
window에서 pulse 수가 다시 6~7개로 돌아오면 즉시 원래 reciprocal 값으로 복귀해 1-sample spike로
보였다. 즉 threshold 근처에 히스테리시스가 없어 정상 속도에서도 pulse 타이밍 지터만으로 estimator
모드가 순간적으로 바뀌는 구조적 결함이었다.

**수정**: `HIGH_COUNT_THRESHOLD=14`, `LOW_COUNT_THRESHOLD=10`(신규 파라미터)로 히스테리시스를
추가했다. window당 pulse 수가 14 이상이어야 window-count 모드로 전환하고, 10 이하로 떨어져야
reciprocal 모드로 복귀하며, 그 사이(11~13)에서는 직전 모드를 유지한다. 테스트한 27.32~40.97 RPM
구간(window당 4.5~6.75 pulse)은 새 threshold보다 충분히 낮아 정상적으로는 절대 window-count
모드에 들어가지 않는다. `laplace/tb/tb_encoder_hybrid.v`에 재발 방지용 회귀 테스트를 추가해
window당 5~6 pulse가 20 sample tick 동안 유지되는 동안 `speed`가 400 Q12 이상 튀지 않고
`high_speed_mode`가 계속 0으로 유지되는지 확인한다. 자세한 threshold 값과 근거는
[DESIGN.md](DESIGN.md)를 참고한다.

**재검증 상태**: MATLAB Online 재실행(PASS) → 공식 XSim 7개 regression(`tb_encoder_hybrid` 포함,
전체 PASS) → Vivado 재합성까지 마쳤다. 기본 route는 setup WNS `-0.015 ns`로 timing을 놓쳤으나
`phys_opt_design`/`route_design -directive AggressiveExplore`로 재최적화해 setup WNS `+0.116 ns`,
hold WHS `+0.093 ns`, DRC Error 0으로 closure했다(재현 Tcl은 `artifacts/postroute_hybrid_fix_timing.tcl`).

최종 bitstream: `artifacts/laplace_pi_hybrid_telemetry.bit`,
SHA-256 `b7e7599ceb13f9e945ebed774f4246533591bf8fa4dda94e7da98634b275758c`.
수정 전(버그 있는) bitstream은 `artifacts/laplace_pi_hybrid_telemetry_pre_hysteresis_fix_obsolete.bit`
(SHA-256 `3e6fc6bb7941510cfc107d037da6d9a33548c9fbf61f7fb60f7b95874761791e`)로 보존했으며 재사용하지
않는다.

Basys3에 재프로그래밍한 뒤 27.32→40.97 RPM step을 3회 재측정했다. 매 회 frame 3,003개, 누락/checksum
오류/fault 전부 0이고 raw `measured_q12`가 `1820`으로 튀는 재발도 없었다. MATLAB `ANALYZE_TELEMETRY`/
`ANALYZE_TRIALS`로 공식 집계한 결과는 다음과 같다(원시 데이터는 `artifacts/experiments/
hybrid_fixed_step_trial_0{1,2,3}.csv`, 개별/집계 지표는 같은 폴더의 `_metrics.csv`,
`hybrid_fixed_trials_summary.csv`).

| 지표 | Hybrid 수정 후 (n=3) | 기존 window-count-only baseline (n=3) |
|---|---:|---:|
| 상승시간 | 0.307 ± 0.006 s | 0.327 ± 0.015 s |
| 오버슈트 | 6.59 ± 0.64% | 7.87 ± 2.51% |
| 정착시간(2%) | 0.82 ± 0.05 s | 8.40 ± 3.25 s |
| 정상상태 RPM | 40.767 ± 0.028 | 40.736 ± 0.003 |
| 정상상태 오차 | -0.506 ± 0.068% | -0.581 ± 0.007% |

정착시간 평균이 8.40 s에서 0.82 s로, 표준편차가 3.25 s에서 0.05 s로 줄었다. 상승시간·오버슈트·
정상상태 오차는 baseline과 비슷한 수준으로 유지됐다. 저속 window-count 양자화가 정착시간 측정을
왜곡한다는 hybrid estimator 도입 근거가 실측으로 확인됐다.

## Bitstream 사용

- `artifacts/laplace_open_loop.bit`: 현재 실물 open-loop 시험용
- `artifacts/laplace.bit`: 안전한 내부 plant 모드이며 실제 motor closed-loop용이 아님
- `artifacts/laplace_pi_closed_loop.bit`: CPR 988.4 보정 최종 PI 실물 시험용
- `artifacts/laplace_pi_closed_loop_cpr771_obsolete.bit`: 첫 폐루프 시험 기록용, 재사용 금지

Open-loop bitstream의 SHA-256은
`9bf58f6bfcd1f406bce613ec3f392c37465ec6198ddfbca1cf6781a89c0a8157`이다.
CPR 771 설정의 첫 PI bitstream은 encoder 주파수 172.4 Hz에 수렴했지만 출력축은 10.47 RPM으로
측정되어 calibration 오류를 발견하는 데 사용됐다. 최종 PI bitstream의 SHA-256은
`a21821031006dc9a44cc4a9703e4d758fd2462ef50669c21680d1d4955edaa37`이다.

## 검증 및 빌드

MATLAB Online:

```matlab
cd Project07_MotorControl
RUN_MATLAB_CHECKS
```

Vivado 2024.2:

```text
python3 -m pip install -r requirements.txt
python3 tools/offline_check.py
python3 tools/run.py sim
python3 tools/run.py build
```

Open-loop commissioning만 다시 생성할 때는 다음 명령을 사용한다.

```text
python3 tools/run.py open-loop-sim
python3 tools/run.py open-loop-build
```

외부 모드는 `vivado/laplace_config.tcl`에서 설정한다. 설정 또는 RTL을 변경하면 MATLAB과 XSim을
다시 실행해야 closed-loop build gate를 통과할 수 있다.

정량 실험은 `tools/capture_telemetry.py`로 reference, speed, duty, integral 및 fault를 CSV에 기록하고
`ANALYZE_TELEMETRY`, `ANALYZE_DISTURBANCE`, `IDENTIFY_MOTOR`로 분석한다. 세 번 이상의 반복 step은
`ANALYZE_TRIALS`가 평균, 표준편차 및 범위를 만든다. 절차는 `docs/TELEMETRY_EXPERIMENT.md`에 있다.

## 안전

- 배선은 Basys3 OFF, PSU OUTPUT OFF 상태에서만 변경한다.
- 일반 오실로스코프 ground clip은 공통 GND에만 연결한다.
- OUT1/OUT2에 scope ground를 연결하지 않는다.
- 시험 시작은 PSU 12.0 V, current limit 0.5 A와 SW0 OFF 상태에서 진행한다.
- 정지, 과전류, 냄새 또는 과열이 발생하면 SW0 OFF 후 PSU OUTPUT을 OFF한다.

## 폴더

| 경로 | 내용 |
|---|---|
| `laplace/rtl` | PID, plant, encoder, PWM 및 Basys3 top |
| `laplace/tb` | 자동 PASS/FAIL testbench 7개 |
| `data` | PID 계수와 1,200-step 기준값 |
| `matlab` | 전달함수, 정수 Golden 및 Simulink 함수 |
| `vivado` | 프로젝트 생성, XSim 및 bitstream Tcl |
| `docs` | 설계 규칙, 하드웨어 배선 및 실물 측정 기록 |
| `artifacts` | bitstream, 구현 보고서, MATLAB 입력과 결과 |
| `HANDOFF.md` | 다음 작업자가 읽을 진행 기록 |

현재 `vivado/laplace_config.tcl`에는 `closed_loop`와 `ENCODER_COUNTS_FULL_SCALE=18`이 적용돼
있다. 기존 PI bitstream과 두 목표 속도의 실물 추종은 완료됐으며, UART가 포함된 새 소스는 전체
MATLAB/XSim/Vivado gate를 다시 통과해야 한다. 석사 수준 확장 범위와 합격 기준은
`docs/MASTERS_EXTENSION.md`에 정의했다.
