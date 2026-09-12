# 작업 인수인계

## 먼저 지킬 조건

- `docs/PROJECT_RULES.md`와 `DESIGN.md`를 먼저 읽는다.
- 소스 또는 동작 모드 변경 뒤 MATLAB과 XSim부터 다시 검증한다.
- 커밋 작성자는 `dlgus0630` 한 명으로 유지하고 공동 작성자 트레일러를 넣지 않는다.
- 엔코더 전압과 L298N 점퍼 상태 확인 전에는 12 V 출력을 켜지 않는다.

## 완료 상태

- MATLAB Golden과 Simulink closed-loop PASS
- XSim `tb_pid_loop`, `tb_pid_limits`, `tb_pwm_encoder`, `tb_laplace_top`, `tb_laplace_motor` PASS
- 1,200 sample PID 기준값, 부하 인가/해제, 목표 반전, reset 검증
- positive/negative saturation과 integral rejection 검증
- external arm, 즉시 차단, encoder normalization, stall fault 검증
- Vivado 2024.2 synthesis/implementation/bitstream PASS
- setup `+0.219 ns`, hold `+0.122 ns`, DRC Error 0

PID의 긴 조합 경로는 10단계 FSM으로 분할했다. 이 변경 후 모든 XSim 기준값이 일치했다.
`artifacts/laplace.bit`은 `internal` 모드이므로 실제 모터 출력이 항상 LOW다.

## 바로 이어서 할 일

1. L298N 전체 단자와 ENA/5V-EN 점퍼, 모터 6핀 케이블을 사진으로 대조한다.
2. encoder VCC, C1/C2 출력 전압, CPR 또는 gearbox 기준 pulse 수를 확인한다.
3. bench supply 출력 OFF에서 공통 GND와 L298N 전원 경로를 구성한다.
4. `open_loop`로 설정하고 MATLAB, XSim, build를 다시 실행한다.
5. 모터 없이 JA1 PWM 20 kHz, 0..3.3 V와 reset/arm 차단을 확인한다.
6. 무부하 25%에서 모터 회전, 전류, C1 pulse/s, 출력축 RPM을 기록한다.
7. 여러 duty에서 최종 속도와 63.2% 도달 시간을 측정해 1차 모델 K와 tau를 구한다.
8. 측정한 `laplace_counts_full_scale`을 넣고 closed-loop를 빌드한다.
9. P부터 조정하고 I를 추가하며 D는 필요한 경우에만 사용한다.

최소 기록값은 supply 전압·전류 제한, duty, 정상상태 전류, C1 pulse/s, 출력축 RPM,
목표 step 후 rise/settling/overshoot, 부하 조건이다. stall 보호는 전류 제한 기능이 아니므로
bench supply의 current limit을 계속 사용한다.

