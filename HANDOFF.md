# 작업 인수인계

## 먼저 지킬 조건

- `docs/PROJECT_RULES.md`, `DESIGN.md`, `README.md`를 먼저 읽는다.
- 소스 또는 동작 모드 변경 뒤 MATLAB과 XSim부터 다시 검증한다.
- 커밋 작성자는 `dlgus0630` 한 명으로 유지하고 공동 작성자 트레일러를 넣지 않는다.
- 배선은 Basys3 OFF와 PSU OUTPUT OFF 상태에서만 변경한다.
- 오실로스코프 ground clip은 공통 GND에만 연결하며 OUT1/OUT2에는 연결하지 않는다.

## 유지할 설계 규칙

1. 검증된 Basys3 Pure RTL 기준선의 재현성과 설명 가능한 구조를 유지한다.
2. MATLAB 전달함수, Simulink, Verilog simulation, synthesis, implementation, 보드 검증 순서를 지킨다.
3. Basys3 기준선에는 AXI를 넣지 않는다. 석사 확장은 별도 Zybo PL/PS 계층으로 진행한다.
4. FPGA가 Laplace transform을 직접 계산한다고 설명하지 않는다. 연속 모델을 이산 제어기로 변환한 구조다.
5. PI, FSM, saturation, anti-windup, PWM과 encoder 처리는 직접 작성한 Verilog-2001로 유지한다.
6. bit width, signedness, saturation 또는 timing 변경 전 `DESIGN.md`를 갱신한다.
7. 모터 상수, encoder CPR과 전류를 추측값으로 확정하지 않는다.
8. internal, open-loop, closed-loop 순서로 검증하고 작은 duty에서 시작한다.
9. Behavioral simulation 실패 상태에서 synthesis로 넘어가지 않는다.
10. 실행하거나 측정하지 않은 결과를 PASS 또는 실측값으로 기록하지 않는다.

## 프로젝트 구성

- 보드: Basys3, Artix-7 XC7A35T
- 모터: JGB37-520, DC 12 V, 110 RPM, Hall encoder
- 드라이버: L298N, ENA jumper 제거
- 제어기: 100 Hz PI, `Kp=0.9`, `Ki=6/s`, `Kd=0`
- PWM: 20 kHz
- 보호: arm 절차, 즉시 출력 차단, encoder stall fault, conditional-integration anti-windup

모터선은 빨강 M1과 흰색 M2다. Encoder는 파랑 VCC, 검정 GND, 초록 C1, 노랑 C2이며 현재
C1만 JA4에 연결한다. Basys3 JA1/JA2/JA3은 각각 L298N ENA/IN1/IN2에 연결한다. PSU, L298N,
Basys3와 encoder는 공통 GND를 사용한다.

## 완료된 검증

- MATLAB Golden 및 Simulink PI closed-loop PASS
- XSim `tb_pid_loop`, `tb_pid_limits`, `tb_pwm_encoder`, `tb_laplace_top`, `tb_laplace_motor` PASS
- 1,200 sample 기준값, 부하 인가/해제, 목표 반전과 reset 검증
- positive/negative saturation 및 anti-windup integral rejection 검증
- external arm, 즉시 차단, encoder normalization과 stall fault 검증
- Basys3 JA1 20 kHz PWM, JA2 HIGH, JA3 LOW 실측 PASS
- L298N open-loop 25% 구동 PASS: 12.0 V, 약 0.07 A
- Encoder C1 약 0~3.3 V 사각파 및 FPGA JA4 입력 PASS

최종 closed-loop Vivado 2024.2 결과:

```text
setup WNS  = +0.060 ns
hold WHS   = +0.122 ns
DRC Errors = 0
LUT        = 450 / 20800 (2.16%)
FF         = 416 / 41600 (1.00%)
DSP        = 4 / 90 (4.44%)
BRAM       = 0
```

## Encoder 보정

초기 open-loop 측정으로 얻은 CPR 771.4는 폐루프 반복 측정과 일치하지 않아 폐기했다. 폐루프 안정
상태에서 다음 두 측정을 동시에 수행했다.

```text
172.4 Hz, 출력축 10회전 57.30 s -> 987.852 pulse/rev
172.4 Hz, 출력축  5회전 28.70 s -> 989.576 pulse/rev
합산 15회전 86.00 s             -> 988.427 pulse/rev
```

최종 설정은 `ENCODER_COUNTS_FULL_SCALE=18`이다. 18 count/10 ms는 1800 pulse/s이고 CPR
988.427 기준 약 109.3 RPM이다.

## 최종 실물 PI 결과

| 설정 | 목표 | Encoder 실측 | 출력축 실측 | 전류 | 판정 |
|---|---|---|---|---|---|
| SW1 | 225 Hz, 13.66 RPM | 221.2 Hz, 13.43 RPM | 5회전 22.40 s, 13.39 RPM | 0.08 A | PASS |
| SW2 | 450 Hz, 27.32 RPM | 446.4 Hz, 27.10 RPM | 5회전 11.10 s, 27.03 RPM | 0.11 A | PASS |

두 운전점에서 encoder와 기계 속도는 약 0.3% 이내로 일치했다. 목표 대비 기계 속도 오차는 각각
-1.94%, -1.06%다. 두 시험 모두 LD1 fault는 OFF였다.

## 최종 파일

- 실물용: `artifacts/laplace_pi_closed_loop.bit`
- 동일 보관본: `artifacts/laplace_pi_closed_loop_cpr988.bit`
- SHA-256: `a21821031006dc9a44cc4a9703e4d758fd2462ef50669c21680d1d4955edaa37`
- 구현 보고서: `artifacts/laplace_pi_closed_loop_{timing,drc,utilization}.rpt`
- MATLAB 결과: `artifacts/matlab_results_cpr990.zip`
- CPR 771 파일: `artifacts/laplace_pi_closed_loop_cpr771_obsolete.bit`, 재사용 금지

## 진행 중인 정량 telemetry 확장

- Basys3 USB-UART A18, 115200 baud, 100 Hz, 16-byte binary frame RTL 구현
- reference, measured speed, duty, integral, arm/fault/enable 및 sequence/checksum 포함
- UART 단위 XSim testbench PASS
- Python checksum/resynchronization test PASS
- MATLAB step/외란/식별 분석과 합성 데이터 self-test 구현
- 기존 estimator telemetry bitstream: MATLAB, XSim 6개, timing/DRC, 보드 programming PASS
- 기존 estimator 27.32 -> 40.97 RPM 3회 baseline capture 완료
- hybrid reciprocal/window estimator와 iterative divider 구현, isolated XSim PASS
- 남은 gate: hybrid 소스 MATLAB Online -> 전체 XSim 7개 -> Vivado timing/DRC -> 비교 capture

## 이후 확장 작업 — 2026-09-15 방향 변경

**이 저장소는 최종 실물 시스템이 아니라 "개발·검증 기준선"으로 역할이 바뀌었다.** 2026-09-15에
Basys3와 Zybo 두 보드를 계속 나눠 유지하는 대신, 이 저장소에서 만든 encoder hybrid
estimator/PI/anti-windup을 `Project07_VibrationNPU`(Zybo Z7-20)의 PL로 이식해 한 보드로
완전히 통합하기로 결정했다. 포트폴리오 서술: "Basys3에서 순수 RTL 모터 폐루프 제어기를
개발·검증한 뒤 Zybo Z7-20 PL로 이식해 ARM 센서 수집, FFT/NPU 진동 분류, 단계별 안전 제어와
통합했다."

이 저장소는 삭제하지 않고 GitHub에 그대로 유지한다 — 통합판이 기준선과 같은 동작을 내는지
비교할 근거이자, "RTL 제어기를 처음부터 직접 설계·검증했다"는 증거로 남긴다.

**따라서 아래는 이 저장소(Basys3)에서 더 진행하지 않는다:**

- 12 -> 9 -> 12 V 외란 시험은 Basys3에서 반복하지 않는다. Zybo 통합판이 완성된 뒤 그쪽에서
  한 번 수행한다. 절차는 아래 "전원 외란 복원" 문서를 Zybo 저장소 쪽에서 참고해 새로 만든다.
- 27.32 -> 40.97 RPM 5회 반복, open-loop 식별, C2 quadrature도 통합판 완성 뒤 필요하면 그쪽에서
  진행 여부를 판단한다. 이 저장소에서 먼저 손대지 않는다.

**이 저장소에서 유지·완료해야 할 것은 이것뿐이다:**

- 현재 기록된 hybrid estimator + PI + telemetry 결과(설정, 코드, 실측치)를 그대로 보존한다.
  Zybo 이식 작업의 원본 참조가 된다.
- 이식 과정에서 이 저장소의 RTL을 고치지 않는다. 참고만 하고 복사해서 옮긴다.

진행 순서와 Zybo 쪽 목표 구조는 `Project07_VibrationNPU/HANDOFF.md`의
"다음 작업 순서 — Zybo 단일보드 완전 통합" 절에 있다.
