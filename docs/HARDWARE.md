# Basys3, JGB37-520, L298N 배선 및 계측

사진에서 모터는 JGB37-520, DC 12 V, 110 RPM, Hall encoder 내장형으로 확인됐다. 엔코더 VCC,
C1/C2 출력 전압, CPR, 감속비와 stall current는 아직 확인되지 않았다.

커넥터를 사진과 같은 방향으로 봤을 때 기판 실크와 선 색상은 다음 조합으로 보인다. 이는 사진에
근거한 후보이며 확정 배선표가 아니다. 전원을 끈 상태에서 M1/M2 연속성, GND, VCC를 먼저 식별하고
encoder 전원을 제한 전류로 공급한 뒤 C1/C2 전압을 확인한다.

| 사진상 선 색상 | 사진상 기판 표기 | 예상 기능 |
|---|---|---|
| 빨강 | M1 | 모터 권선 |
| 검정 | GND | encoder GND |
| 노랑 | C2 | Hall channel B |
| 초록 | C1 | Hall channel A |
| 파랑 | VCC | encoder VCC |
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

보정식은 C1 상승 에지 기준으로
`counts_full_scale = CPR * reference_RPM / 60 * 0.01`이다. CPR과 RPM은 같은 축 기준이어야 한다.
