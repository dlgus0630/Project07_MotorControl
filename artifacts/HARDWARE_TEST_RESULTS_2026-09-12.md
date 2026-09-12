# 실물 시험 결과

## 완료된 부품 단독 시험

| 항목 | 시험 조건 | 측정 결과 | 판정 |
|---|---|---|---|
| 모터 권선 | 빨강-흰색 저항 및 축 회전 | 약 130~150 Ω, 회전 시 변동 | 배선 확인 |
| 모터 구동 | DC 3.0 V 직접 인가 | 정상 회전 | PASS |
| 모터 전류 | DC 3.0 V, 무부하 | 약 0.09~0.11 A | 확인 |
| 회전 방향 | 출력축 정면 기준 | CW | 확인 |
| encoder 전원 | DC 3.3 V | 약 0.01 A | 확인 |
| encoder C1 | 초록선, 오실로스코프 | 사각파 | PASS |
| C1 주기 | DC 3.0 V 모터 구동 시 | 약 2.8~2.9 ms | 확인 |
| C1 주파수 | DC 3.0 V 모터 구동 시 | 약 342~354 Hz | 확인 |
| C1 전압 | encoder 3.3 V 공급 시 | 약 0~3.6 V | 직결 전 재확인 |
| encoder C2 | 노랑선 | 미측정 | 선택 시험 |

## Basys3 출력 단독 시험

2026-09-12에 `artifacts/laplace_open_loop.bit`을 Basys3에 JTAG로 내려받아 L298N과 모터를
분리한 상태에서 측정했다. `SW3..SW1=010`으로 25% 목표를 선택하고 `SW0` OFF→ON으로 arm했다.

| 항목 | 측정 결과 | 판정 |
|---|---:|---:|
| JA1 PWM | 20.00 kHz, 약 25%, 0~3.3 V | PASS |
| JA2 IN1 | 약 3.3 V HIGH | PASS |
| JA3 IN2 | 약 0 V LOW | PASS |
| SW0 OFF 후 JA1 | LOW | PASS |
| SW0 OFF 후 JA2 | LOW | PASS |

LD5, LD3, LD0 점등으로 external mode, PWM, arm 상태를 함께 확인했고 fault 표시 LD1은
점등되지 않았다. 이 시험으로 Basys3의 open-loop 제어 출력과 즉시 정지 동작을 확인했다.

확인된 배선은 빨강 `M1`, 흰색 `M2`, 파랑 encoder `VCC`, 검정 encoder `GND`, 초록 `C1`이다.
노랑 `C2`는 기판 표기와 배선 순서로 식별했으며 파형은 측정하지 않았다.

C1의 사각파로 encoder 동작은 확인했다. 다만 3.3 V 공급에서 약 3.6 V HIGH가 관찰됐으므로 이를
Basys3 입력 적합성 PASS로 기록하지 않는다. probe 설정과 공통 GND를 확인해 HIGH 평탄부와 overshoot를
다시 측정한다. 안정된 HIGH가 3.3 V를 넘으면 level shifter 또는 검증된 분압 회로를 사용한다.

현재 342~354 Hz만으로 CPR이나 `laplace_counts_full_scale`을 정하지 않는다. 당시 출력축 RPM을
동시에 측정하지 않았고 3 V 조건은 정격 12 V 조건과 다르기 때문이다.

## 남은 최소 시험

1. L298N의 ENA 점퍼를 제거하고 5V-EN 및 전원 단자를 식별한다.
2. 전원 OFF에서 L298N, 모터와 공통 GND를 배선한다.
3. 12 V, 0.3~0.5 A 제한에서 open-loop 25% 구동을 확인한다.
4. 같은 조건에서 C1 pulse/s와 출력축 RPM을 동시에 기록한다.
5. 측정값으로 encoder 환산값을 정한 뒤 closed-loop PID를 시험한다.

## 보고용 문장

JGB37-520 모터를 3.0 V에서 단독 시험한 결과 출력축 정면 기준 CW로 정상 회전했고 무부하 전류는
약 0.09~0.11 A였다. Encoder에 3.3 V를 공급해 C1을 측정한 결과 약 342~354 Hz의 사각파를
확인했다. Basys3에서 20.00 kHz, 약 25%의 0~3.3 V PWM과 IN1=HIGH, IN2=LOW 및 SW0 정지를
확인했다. L298N을 통한 모터 구동, encoder 환산값 측정과 PID closed-loop 검증은 남아 있다.
