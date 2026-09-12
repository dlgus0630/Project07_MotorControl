# 프로젝트 원칙

1. 범위는 학부 수준, 중간 난이도로 유지하고 설명 가능한 완성도를 우선한다.
2. MATLAB 전달함수, Simulink, Verilog simulation, synthesis, implementation, 보드 검증 순서를 지킨다.
3. Behavioral simulation이 실패하면 synthesis로 넘어가지 않는다.
4. Basys3 Pure RTL로 유지하고 MicroBlaze, AXI, NPU를 추가하지 않는다.
5. FPGA가 Laplace transform을 계산한다고 설명하지 않는다. 연속 모델을 이산 제어기로 변환한 구조다.
6. PID, FSM, saturation, anti-windup, PWM과 encoder 처리는 직접 작성한 RTL을 사용한다.
7. 직접 작성하는 HDL은 Verilog-2001 `.v`만 사용하고 HDL Coder를 사용하지 않는다.
8. bit width, signedness, saturation과 timing을 변경하기 전에 `DESIGN.md`를 갱신한다.
9. 실제 모터 상수, 엔코더 CPR과 전류를 추측값으로 확정하지 않는다.
10. internal, open-loop, closed-loop 순서로 검증하고 작은 duty에서 시작한다.
11. 실행하거나 측정하지 않은 결과를 PASS 또는 실측값으로 기록하지 않는다.
12. 커밋 작성자는 `dlgus0630` 한 명으로 유지하고 공동 작성자 메타데이터를 추가하지 않는다.
