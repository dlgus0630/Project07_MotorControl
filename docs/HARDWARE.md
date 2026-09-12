# Basys3, JGB37-520, L298N 배선 및 계측

사진에서 모터는 JGB37-520, DC 12 V, 110 RPM, Hall encoder 내장형으로 확인됐다. 모터 단독
구동과 C1 사각파 측정까지 완료했다. CPR, 감속비와 stall current는 아직 확인되지 않았다.

커넥터 배선은 기판 실크, 저항 측정, 3 V 모터 구동과 3.3 V encoder 시험으로 확인했다. C2는
기판 표기로 식별했지만 파형은 측정하지 않았다.

| 선 색상 | 기판 표기 | 기능 |
|---|---|---|
| 빨강 | M1 | 모터 권선 |
| 검정 | GND | encoder GND |
| 노랑 | C2 | Hall channel B, 파형 미측정 |
| 초록 | C1 | Hall channel A, 사각파 확인 |
| 파랑 | VCC | encoder VCC, 3.3 V 시험 완료 |
| 흰색 | M2 | 모터 권선 |

| 모터 기판 표기 | 기능 |
|---|---|
| M1, M2 | L298N OUT1/OUT2에 연결할 모터 권선 |
| VCC, GND | encoder 전원, 정격 확인 전 연결 금지 |
| C1, C2 | Hall encoder 두 채널 |

| Basys3 | L298N/encoder |
|---|---|
| JA1 | ENA, ENA 점퍼 제거 |
| JA2 | IN1 |
| JA3 | IN2 |
| JA4 | 전압 호환 확인 또는 변환된 C1 |
| GND | L298N, encoder, 전원 공통 GND |

12 V는 L298N 모터 전원 단자에만 연결한다. Basys3 또는 encoder VCC에 연결하지 않는다.
L298N 5V-EN 점퍼와 ENA 점퍼는 서로 다르므로 실제 모듈 사진으로 상태를 확인한다.
ENA에는 약 10 kΩ GND pull-down을 권장한다.
사진에는 점퍼가 장착된 것으로 보이지만 위치의 실크가 선명하지 않아 기능은 아직 확정하지 않았다.

일반 오실로스코프 probe ground는 회로 GND에만 연결한다. OUT1 또는 OUT2에 ground clip을
연결하지 않는다. 모터 차동 전압은 CH1/CH2를 OUT1/OUT2에 연결하고 `CH1-CH2`로 측정한다.

bench supply는 출력 OFF에서 배선하고 12.0 V, 0.3~0.5 A 전류 제한으로 시작한다. encoder는
전압 사양 확인 후 별도 제한 전류로 시험한다. open-loop 25%에서 PWM과 C1 pulse를 먼저 측정하고,
회전하지 않으면 오래 유지하지 않는다.

3.3 V encoder 공급에서 C1 HIGH가 약 3.6 V로 관찰됐다. Basys3 JA4에 연결하기 전에 probe 설정과
공통 GND를 확인해 안정된 HIGH와 overshoot를 구분한다. 안정된 HIGH가 3.3 V를 넘으면 level shifter
또는 검증된 분압 회로를 사용한다. 상세 측정값은 `docs/HARDWARE_TEST_RESULTS.md`에 기록했다.

보정식은 C1 상승 에지 기준으로
`counts_full_scale = CPR * reference_RPM / 60 * 0.01`이다. CPR과 RPM은 같은 축 기준이어야 한다.
