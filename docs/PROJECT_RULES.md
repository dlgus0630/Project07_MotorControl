# 프로젝트 원칙

1. 검증된 Basys3 Pure RTL 기준선은 유지하고, 석사 수준 확장은 별도 계측 및 Zybo SoC 계층으로 추가한다.
2. MATLAB 전달함수, Simulink, Verilog simulation, synthesis, implementation, 보드 검증 순서를 지킨다.
3. Behavioral simulation이 실패하면 synthesis로 넘어가지 않는다.
4. Basys3 기준선에는 MicroBlaze나 AXI를 넣지 않는다. Zybo 확장에서는 AXI4-Lite와 PS 소프트웨어를 사용한다.
5. FPGA가 Laplace transform을 계산한다고 설명하지 않는다. 연속 모델을 이산 제어기로 변환한 구조다.
6. PID, FSM, saturation, anti-windup, PWM과 encoder 처리는 직접 작성한 RTL을 사용한다.
7. 직접 작성하는 HDL은 Verilog-2001 `.v`만 사용하고 HDL Coder를 사용하지 않는다.
8. bit width, signedness, saturation과 timing을 변경하기 전에 `DESIGN.md`를 갱신한다.
9. 실제 모터 상수, 엔코더 CPR과 전류를 추측값으로 확정하지 않는다.
10. internal, open-loop, closed-loop 순서로 검증하고 작은 duty에서 시작한다.
11. 실행하거나 측정하지 않은 결과를 PASS 또는 실측값으로 기록하지 않는다.
12. 커밋 작성자는 `dlgus0630` 한 명으로 유지하고 공동 작성자 메타데이터를 추가하지 않는다.
13. 제어 성능은 반복 실험의 원시 CSV와 MATLAB 산출물로 증명하며 단일 화면 측정만으로 일반화하지 않는다.
14. 모델 식별은 train/validation/test 구간을 분리하고, 새 제어계수는 simulation 뒤 실물에 적용한다.
15. SoC에서도 100 Hz hard real-time loop와 보호 기능은 PL이 소유하고 PS 정지 시에도 safe state로 전이한다.
