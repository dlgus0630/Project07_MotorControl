# 작업 인수인계

## 먼저 지킬 조건

- `docs/PROJECT_RULES.md`와 `DESIGN.md`를 먼저 읽는다.
- 소스 또는 동작 모드 변경 뒤 MATLAB과 XSim부터 다시 검증한다.
- 커밋 작성자는 `dlgus0630` 한 명으로 유지하고 공동 작성자 트레일러를 넣지 않는다.
- 엔코더 전압과 L298N 점퍼 상태 확인 전에는 12 V 출력을 켜지 않는다.

## 유지할 설계 규칙

1. 학부 수준의 중간 난이도와 설명 가능한 완성도를 유지한다.
2. MATLAB 전달함수, Simulink, Verilog simulation, synthesis, implementation, 보드 검증 순서를 지킨다.
3. Basys3 Pure RTL 구조를 유지하며 MicroBlaze, AXI 또는 NPU를 추가하지 않는다.
4. FPGA가 Laplace transform을 직접 계산한다고 설명하지 않는다. 연속 모델을 이산 제어기로 변환한 구조다.
5. PID, FSM, saturation, anti-windup, PWM과 encoder 처리는 직접 작성한 Verilog-2001로 유지한다.
6. bit width, signedness, saturation 또는 timing 변경 전 `DESIGN.md`를 갱신한다.
7. 모터 상수, encoder CPR과 전류를 추측값으로 확정하지 않는다.
8. internal, open-loop, closed-loop 순서로 검증하고 작은 duty에서 시작한다.
9. Behavioral simulation 실패 상태에서 synthesis로 넘어가지 않는다.
10. 실행하거나 측정하지 않은 결과를 PASS 또는 실측값으로 기록하지 않는다.

## 완료 상태

- MATLAB Golden과 Simulink closed-loop PASS
- XSim `tb_pid_loop`, `tb_pid_limits`, `tb_pwm_encoder`, `tb_laplace_top`, `tb_laplace_motor` PASS
- 1,200 sample PID 기준값, 부하 인가/해제, 목표 반전, reset 검증
- positive/negative saturation과 integral rejection 검증
- external arm, 즉시 차단, encoder normalization, stall fault 검증
- Vivado 2024.2 synthesis/implementation/bitstream PASS
- setup `+0.219 ns`, hold `+0.122 ns`, DRC Error 0

위 결과는 분리 전 동일 RTL의 공식 검증 결과이며 `artifacts/`에 증거를 보관했다. 저장소가
`Project08_MotorControl`로 분리되면서 소스 해시가 달라졌으므로, 다음 build 전에
`artifacts/matlab_input.zip`을 MATLAB Online에서 실행하고 XSim을 다시 실행해야 한다. gate를
통과시키기 위해 결과 파일이나 해시를 수동으로 만들지 않는다.

PID의 긴 조합 경로는 10단계 FSM으로 분할했다. 이 변경 후 모든 XSim 기준값이 일치했다.
`artifacts/laplace.bit`은 `internal` 모드이므로 실제 모터 출력이 항상 LOW다.

## 바로 이어서 할 일

1. 사진에서 모터 6핀 실크와 선 색상을 대조했다. `docs/HARDWARE.md`의 후보 배선을 무전원 연속성
   측정으로 확정하고 L298N의 ENA/5V-EN 점퍼 실크를 직접 읽는다.
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
