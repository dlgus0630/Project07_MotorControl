# 설계 계약

## 모터와 이산 모델

연속 모델은 `G(s)=Kt/((Js+B)(Ls+R)+KtKe)`다. 초기 예제값은 R=2 Ω, L=0.002 H,
J=0.0002, B=0.0001, Kt=Ke=0.05이며 실제 JGB37-520 측정값이 아니다.
전기 시정수가 기계 시정수보다 작다는 가정으로 normalized 1차 모델을 사용한다.

`Ts=10 ms`, `y[k+1]=a*y[k]+(1-a)*max(u[k]-load[k],0)`이며 exact ZOH 계수를 사용한다.
PID 초기값은 Kp=0.9, Ki=6/s, Kd=0.0015 s, measurement derivative filter alpha=1/4다.
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

PID는 긴 조합 경로를 피하기 위해 10단계 FSM으로 계산한다. 제어기는 100 Hz tick 안에서 완료된다.

## 동작 모드

- `internal`: 내부 test plant, 물리 모터 출력 LOW
- `open_loop`: SW3..1이 0..87.5% PWM을 직접 선택
- `closed_loop`: C1 상승 에지 기반 속도 feedback PID

reset 뒤 SW0을 OFF에서 ON으로 바꿔야 arm된다. 외부 모드에서 duty가 25%보다 크고 300 ms 동안
encoder pulse가 없으면 fault latch가 걸린다. closed-loop 빌드는 측정한
`laplace_counts_full_scale`이 없으면 차단한다.

