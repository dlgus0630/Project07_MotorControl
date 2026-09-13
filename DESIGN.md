# 설계 계약

## 모터와 이산 모델

연속 모델은 `G(s)=Kt/((Js+B)(Ls+R)+KtKe)`다. 초기 예제값은 R=2 Ω, L=0.002 H,
J=0.0002, B=0.0001, Kt=Ke=0.05이며 실제 JGB37-520 측정값이 아니다.
전기 시정수가 기계 시정수보다 작다는 가정으로 normalized 1차 모델을 사용한다.

`Ts=10 ms`, `y[k+1]=a*y[k]+(1-a)*max(u[k]-load[k],0)`이며 exact ZOH 계수를 사용한다.
첫 실물 closed-loop 제어기는 Kp=0.9, Ki=6/s, Kd=0인 PI다. Measurement derivative state는
향후 PID 비교를 위해 유지하지만 현재 출력에는 사용하지 않는다.
출력 포화를 더 키우는 방향의 적분 갱신은 거부한다.

## 수치 형식

| 데이터 | 형식 |
|---|---|
| reference, feedback, duty | unsigned 13-bit, 0..4096 = 0..1 pu |
| error, filtered derivative | signed 18-bit |
| coefficient | signed Q16.16 |
| product/sum | signed 64-bit 중간값 |
| integral contribution | signed INT32, ±4096 clamp |
| PWM | 20 kHz, 주기 경계 duty 갱신, 명시적 100% |

Encoder 정규화는 비-2의 거듭제곱 실측 상수의 조합 나눗셈을 피하기 위해 Q12 reciprocal 곱셈을
사용한다. `COUNTS_FULL_SCALE=18`에서 9 pulse/10 ms는 정확히 0.5 pu인 2048로 변환된다.

저속에서는 10 ms window 안의 정수 pulse 수가 큰 양자화 오차를 만든다. 따라서 C1 pulse 사이의
100 MHz clock 수를 32-cycle iterative divider로 역산하고 4-sample IIR을 적용한다. 10 ms에
`HIGH_COUNT_THRESHOLD=14` 이상이면 window-count, `LOW_COUNT_THRESHOLD=10` 이하로 내려가면
reciprocal-period 결과로 전환하고, 그 사이(11~13 pulse)에서는 직전 모드를 유지하는 히스테리시스를
쓴다. 100 ms 동안 pulse가 없으면 속도를 0으로 만들며 기존 stall fault가 출력을 차단한다.

실측 CPR 988.4, `COUNTS_FULL_SCALE=18` 기준으로 27.32~40.97 RPM 구간은 window당 4.5~6.75 pulse다.
최초 구현은 단일 threshold(8, 히스테리시스 없음)를 썼는데, 6.75 pulse 평균에서 타이밍 지터만으로
window당 pulse 수가 8에 닿는 경우가 실물에서 30초당 약 3회 관측됐다. 그 순간 window-count 결과가
그대로 출력돼 40.9 RPM 근처에서 48.55 RPM으로 튀는 1-sample glitch가 생겼다(자세한 원인은
README.md 트러블슈팅 참고). threshold를 14/10으로 올리고 히스테리시스를 추가해 테스트한 27.32~
40.97 RPM 구간 전체가 reciprocal 모드에 확실한 여유를 두고 머무르도록 했다.

PID는 긴 조합 경로를 피하기 위해 10단계 FSM으로 계산한다. 제어기는 100 Hz tick 안에서 완료된다.

## 실물 응답 계측

Basys3의 USB-UART `RsTx` 핀으로 115200 baud binary telemetry를 전송한다. PI 계산이 끝나는 100 Hz
`pid_done`마다 16-byte frame 하나를 보내며 전송시간은 다음 제어 tick보다 짧다. 제어 경로와 UART는
ready/busy handshake로 분리하고 UART가 바쁘면 제어 동작을 멈추지 않는다.

| Byte | 내용 |
|---|---|
| 0..1 | sync `A5 5A` |
| 2..3 | 16-bit sample sequence, little endian |
| 4..5 | reference Q12 |
| 6..7 | measured speed Q12 |
| 8..9 | PWM duty Q12 |
| 10..13 | signed integral Q12, little endian |
| 14 | flags: bit0 armed, bit1 fault, bit2 enabled |
| 15 | byte 0..14 XOR checksum |

PC logger는 frame checksum과 sequence를 검사해 CSV로 저장한다. MATLAB 분석은 100 Hz 측정치에
10-sample moving average를 적용한 뒤 목표 step의 10~90% 상승시간, overshoot, 2% 정착시간과
마지막 2초 정상상태 오차를 계산한다.

## 동작 모드

- `internal`: 내부 test plant, 물리 모터 출력 LOW
- `open_loop`: SW3..1이 0..87.5% PWM을 직접 선택
- `closed_loop`: C1 상승 에지 기반 속도 feedback PI

reset 뒤 SW0을 OFF에서 ON으로 바꿔야 arm된다. 외부 모드에서 duty가 25%보다 크고 300 ms 동안
encoder pulse가 없으면 fault latch가 걸린다. closed-loop 빌드는 측정한
`laplace_counts_full_scale`이 없으면 차단한다. 폐루프 안정 상태에서 반복 측정한 출력축 실측 CPR
약 988.4와 110 RPM 기준으로 `laplace_counts_full_scale=18`을 사용한다.
