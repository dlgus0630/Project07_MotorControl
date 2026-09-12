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
- 수정된 IN1=HIGH/IN2=LOW open-loop XSim commissioning PASS
- open-loop Vivado 2024.2 build PASS: setup `+3.142 ns`, hold `+0.122 ns`, DRC Error 0
- open-loop 자원: LUT 84, FF 180, DSP 1, BRAM 0
- JGB37-520 빨강/흰색 모터선 확인, 3.0 V 단독 구동 PASS
- 3.0 V 무부하 전류 약 0.09~0.11 A, 출력축 정면 기준 CW
- encoder 3.3 V/약 0.01 A, C1 342~354 Hz 사각파 확인

위 결과는 분리 전 동일 RTL의 공식 검증 결과이며 `artifacts/`에 증거를 보관했다. 저장소가
`Project07_MotorControl`로 분리되면서 소스 해시가 달라졌으므로, 다음 build 전에
`artifacts/matlab_input.zip`을 MATLAB Online에서 실행하고 XSim을 다시 실행해야 한다. gate를
통과시키기 위해 결과 파일이나 해시를 수동으로 만들지 않는다.

PID의 긴 조합 경로는 10단계 FSM으로 분할했다. 이 변경 후 모든 XSim 기준값이 일치했다.
`artifacts/laplace.bit`은 `internal` 모드이므로 실제 모터 출력이 항상 LOW다.

실물 시험 준비 중 기존 외부 출력이 JA2와 JA3를 동시에 HIGH로 만들어 L298N brake 상태가 되는
문제를 발견했다. top port를 `motor_in1`, `motor_in2`로 명확히 바꾸고 외부 구동 시 IN1=HIGH,
IN2=LOW가 되도록 수정했으며 testbench에도 이 조건을 추가했다. 현재 수정본은 open-loop XSim과
Vivado 구현을 통과했다. 전체 closed-loop 5개 testbench는 새 MATLAB gate 후 다시 실행한다.

MATLAB Online 세션 장애 때문에 open-loop 시험은 별도 commissioning gate로 분리했다. 이 경로는
PID/plant 결과를 주장하지 않으며 `tb_laplace_motor`로 PWM, IN1/IN2, arm, reset과 stall 차단만
검증한 뒤 `laplace_open_loop.bit`을 만든다. closed-loop에는 이 우회 경로를 사용하지 않는다.

첫 외부 open-loop 구현에서 encoder 기본 환산값 200의 조합 나눗셈이 setup timing을 위반했다.
Open-loop는 raw pulse 표시만 사용하므로 기본값을 256으로 바꿔 shift로 합성되게 했다. 실제
closed-loop 환산값은 측정 후 순차 연산 또는 reciprocal multiply로 구현해야 한다.

실물 open-loop 시험용 파일은 `artifacts/laplace_open_loop.bit`이다. SHA-256은
`9bf58f6bfcd1f406bce613ec3f392c37465ec6198ddfbca1cf6781a89c0a8157`이며, 기존
`artifacts/laplace.bit`은 외부 출력이 LOW인 internal 모드이므로 혼동하지 않는다.

## 바로 이어서 할 일

1. L298N의 ENA/5V-EN 점퍼와 전원 단자를 실크로 확정한다.
2. C1의 약 3.6 V HIGH가 평탄부인지 overshoot인지 재측정하고 JA4 입력 보호 방법을 정한다.
3. bench supply 출력 OFF에서 공통 GND와 L298N 전원 경로를 구성한다.
4. `artifacts/laplace_open_loop.bit`을 Basys3에 올리고 모터 없이 JA1 PWM 20 kHz,
   0..3.3 V와 JA2=HIGH, JA3=LOW를 확인한다.
5. 무부하 25%에서 모터 회전, 전류, C1 pulse/s, 출력축 RPM을 동시에 기록한다.
6. closed-loop로 넘어갈 때 새 `artifacts/matlab_input.zip`으로 MATLAB을 실행하고 전체 XSim을
   다시 통과시킨다.
7. 측정한 `laplace_counts_full_scale`을 넣고 closed-loop를 빌드한다.
8. P부터 조정하고 I를 추가하며 D는 필요한 경우에만 사용한다.

최소 기록값은 supply 전압·전류 제한, duty, 정상상태 전류, C1 pulse/s, 출력축 RPM,
목표 step 후 rise/settling/overshoot, 부하 조건이다. stall 보호는 전류 제한 기능이 아니므로
bench supply의 current limit을 계속 사용한다.
