# 실물 시험 결과

## 완료된 시험

| 항목 | 시험 조건 | 측정 결과 | 판정 |
|---|---|---|---|
| 모터 권선 | 빨강-흰색 저항 및 축 회전 | 약 130~150 ohm, 회전 시 변동 | 배선 확인 |
| 모터 단독 구동 | DC 3.0 V | CW 회전, 약 0.09~0.11 A | PASS |
| JA1 PWM | SW2+SW0 ON | 20 kHz, 약 25%, 약 0~3.3 V | PASS |
| JA2/JA3 | 정방향 | 약 3.39 V / 약 0 V | PASS |
| L298N ENA | JA1 연결 후 측정 | JA1과 동일한 PWM | PASS |
| L298N open-loop | PSU 12.0 V, 25% PWM | 연속 회전, 약 0.07 A | PASS |
| Encoder C1 | Basys3 3.3 V, JA4 입력 | 약 0~3.3 V 디지털 pulse | PASS |
| C1 주파수 | 위 open-loop 조건 | 약 90.75 Hz | PASS |
| FPGA C1 입력 | SW4 pulse-count 표시 | LED count 변화 | PASS |
| 출력축 속도 | 10회전 85.0 s | 약 7.06 RPM | 확인 |
| 첫 CPR 추정 | open-loop 90.75 Hz, 10회전 85.0 s | 약 771.4 pulse/output-rev | 재현되지 않아 폐기 |
| 폐루프 보정 측정 1 | 172.4 Hz, 10회전 57.30 s | 약 987.9 pulse/output-rev | 확인 |
| 폐루프 보정 측정 2 | 172.4 Hz, 5회전 28.70 s | 약 989.6 pulse/output-rev | 확인 |
| 최종 C1 CPR | 총 15회전 86.00 s | 약 988.4 pulse/output-rev | 확정 |
| PI 목표 1 | SW1, 목표 225 Hz/13.66 RPM | 221.2 Hz, 5회전 22.40 s, 0.08 A, LD1 OFF | PASS |
| PI 목표 2 | SW2, 목표 450 Hz/27.32 RPM | 446.4 Hz, 5회전 11.10 s, 0.11 A, LD1 OFF | PASS |
| Encoder C2 | 노랑선 | 미측정, 미연결 | 선택 시험 |

## Encoder 환산

```text
C1 CPR measurement 1 = 172.4 * 57.30 / 10 = 987.852 pulse/rev
C1 CPR measurement 2 = 172.4 * 28.70 / 5 = 989.576 pulse/rev
C1 CPR combined = 172.4 * (57.30 + 28.70) / 15 = 988.427 pulse/rev
counts_full_scale = 988.427 * 110 / 60 * 0.01 = 18.12 -> 18
```

CPR은 C1 상승 에지와 gearbox 출력축을 같은 기준으로 두 번 반복 측정한 실측값이다. 두 결과의
차이는 약 0.17%다. 10 ms encoder window와 110 RPM full-scale을 사용하는 closed-loop RTL에는
`ENCODER_COUNTS_FULL_SCALE=18`을 적용한다. 이 설정에서 SW1 목표는 C1 225 Hz, 약 13.66 RPM이다.

## PI 폐루프 추종 결과

```text
SW1 mechanical RPM = 300 / 22.40 = 13.39 RPM
SW1 encoder RPM = 60 * 221.2 / 988.427 = 13.43 RPM
SW1 mechanical target error = -1.94%

SW2 mechanical RPM = 300 / 11.10 = 27.03 RPM
SW2 encoder RPM = 60 * 446.4 / 988.427 = 27.10 RPM
SW2 mechanical target error = -1.06%
```

두 운전점에서 encoder 환산값과 출력축 실측값의 차이는 약 0.3% 이내였다. SW1의 C1 주파수는
약 219.2~225.2 Hz 사이에서 변했으며 대표값은 221.2 Hz였다. 두 시험 모두 모터는 연속 회전했고
stall fault인 LD1은 OFF였다.

최종 CPR 988.4 보정 소스는 MATLAB/Simulink, XSim testbench 5개와 Vivado 2024.2 구현을 통과했다.
최종 구현 결과는 setup slack +0.060 ns, hold slack +0.122 ns, DRC Error 0, LUT 450, FF 416,
DSP 4, BRAM 0이다.

## 선택 확장 시험

1. 시간축 reference step response를 기록해 상승시간, overshoot와 정착시간을 계산한다.
2. 재현 가능한 외란 부하를 인가하고 속도 복원시간을 측정한다.
3. C2를 연결해 방향 검출이 필요한 양방향 제어로 확장한다.

## 안전 메모

배선은 Basys3 OFF와 PSU OUTPUT OFF 상태에서만 변경한다. Scope ground는 공통 GND에만 연결한다.
ENA probing 중 물리적 접촉으로 모터가 일시 정지한 사례가 있으므로 실제 motor 시험 중 ENA probe를
건드리지 않는다.
