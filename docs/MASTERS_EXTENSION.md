# FPGA/SoC 석사 수준 확장

## 목표

검증된 Basys3 PI 제어기를 기준선으로 보존하고, 정량 실험과 Zybo Z7-20 PL/PS 공동설계를 추가한다.
기업 면접에서 RTL 구현만 보여주는 데 그치지 않고 요구사항, 인터페이스 계약, 모델 식별, 검증,
타이밍 closure, 실물 계측과 HW/SW 분할을 하나의 재현 가능한 흐름으로 제시하는 것이 목표다.

## 1단계: 정량 telemetry와 제어 성능

FPGA가 100 Hz마다 reference, measured speed, duty, integral과 fault를 USB-UART로 전송한다. PC logger는
sync, XOR checksum과 sequence discontinuity를 검사하고 원시 CSV를 보존한다.

완료 조건:

- UART frame RTL 단위시험과 전체 XSim regression PASS
- 구현 후 setup/hold timing PASS, DRC Error 0, utilization 기록
- 기존 window-count와 hybrid estimator에서 27.32 -> 40.97 RPM step을 각각 3회
- 각 trial의 10~90% rise time, overshoot, 2% settling time, steady error
- 각 방식 3회의 평균, 표준편차, 최소와 최대값 및 정상상태 speed jitter 비교
- 12 -> 9 -> 12 V 외란 3회 및 recovery time

## 2단계: 실측 기반 모델 식별과 제어기 비교

Open-loop duty를 여러 운전점으로 바꾸며 30초 이상 기록한다. 60% train 구간으로 1차+dead-time
모델을 추정하고 20% validation 구간으로 delay를 선택한 뒤 마지막 20% test 구간의 RMSE와 fit을
최종 성능으로 보고한다. 식별 데이터와 검증 데이터의 입력 변화가 모두 포함되도록 시험한다.

식별 모델로 IMC PI 후보를 계산하되 즉시 모터에 적용하지 않는다. Golden model, XSim saturation 및
anti-windup 시험을 통과한 다음 동일한 실물 step 조건에서 기존 PI와 비교한다.

완료 조건:

- plant gain, time constant, dead time 및 test fit 보고
- baseline PI와 model-derived PI의 rise/overshoot/settling/steady-error 표
- 포화 뒤 복원 실험으로 anti-windup 효과 비교
- 원시 CSV, 분석 코드, 계수와 bitstream SHA-256 보관

## 3단계: 저속 encoder estimator와 quadrature

현재 10 ms pulse-count 방식은 저속에서 한 count의 영향이 크다. C1 pulse period를 clock 단위로
측정하는 reciprocal estimator를 추가하고, 속도에 따라 period 방식과 window-count 방식을 전환한다.
C2도 입력받아 quadrature state transition table로 방향과 invalid transition을 검출한다.

완료 조건:

- 저속 10~40 RPM에서 기존 방식 대비 RMS quantization error 비교
- 속도 estimator 전환점의 불연속 제한
- 정방향/역방향/illegal transition self-checking testbench
- encoder timeout과 overflow 시 명시적인 fault 처리

## 4단계: Zybo Z7-20 SoC 공동설계

100 Hz 제어 loop, PWM, encoder와 보호 FSM은 PL에 둔다. PS는 목표값과 계수를 설정하고 telemetry를
저장한다. PS가 멈춰도 PL watchdog가 motor output을 차단할 수 있어야 한다.

권장 구조:

```text
Linux or bare-metal application
        | AXI4-Lite: version/status/reference/coefficients/command
        | interrupt + AXI-Stream FIFO: timestamped telemetry
Zynq PS --------------------------------------------------------
Zynq PL  motor-control core -> PWM/H-bridge -> motor
          encoder estimator <- C1/C2
          safety FSM + watchdog
```

100 Hz, frame당 수십 byte이므로 DMA는 기본 설계에 필요하지 않다. interrupt/FIFO로 실제 처리량과
CPU 부하를 측정한 뒤 DMA가 필요한 근거가 생길 때만 추가한다.

AXI register 요구사항:

- read-only IP version, capability, status, fault cause, sample counter
- shadow reference/Kp/Ki와 atomic apply command
- arm command는 FPGA reset 후 명시적인 OFF -> ON 순서 필요
- write-one-to-clear fault와 PS heartbeat watchdog
- telemetry overflow/drop counter

완료 조건:

- AXI protocol 및 register self-checking simulation
- PL 단독 안전 동작과 PS 정지/watchdog 실물 시험
- PS logger가 timestamp, reference, speed, duty, integral, fault를 CSV로 저장
- Basys3와 Zybo에서 동일한 controller core Golden vector 통과
- timing, utilization, interrupt rate, CPU load와 end-to-end latency 보고

## 포트폴리오에서 보여줄 핵심 증거

두 장 구성이라면 첫 장에는 PL datapath/FSM, fixed-point 형식, timing/utilization과 verification matrix를
배치한다. 두 번째 장에는 실측 step/외란 그래프, 식별 모델의 test fit, PI 비교표와 Zybo HW/SW
architecture를 배치한다. “회전 성공”보다 수치, 실패를 발견한 과정, calibration 수정과 재현 절차가
평가 가치가 높다.
