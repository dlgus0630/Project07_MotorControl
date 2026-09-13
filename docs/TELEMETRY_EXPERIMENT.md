# 정량 제어 실험

## 목적

USB-UART telemetry로 FPGA 내부 reference, encoder speed, PWM duty, integral과 fault를 100 Hz로
동시에 기록한다. 결과는 단순 회전 여부가 아니라 제어기의 상승시간, overshoot, 정착시간,
정상상태 오차와 외란 복원시간을 재현 가능한 수치로 남긴다.

## 폐루프 목표 step

1. 최종 telemetry bitstream을 올리고 PSU를 12.0 V, current limit 0.5 A로 설정한다.
2. `SW2+SW0`으로 약 27.32 RPM에서 안정화한다.
3. PC에서 아래 명령을 실행한다.
4. `EVENT 1 NOW`가 출력되면 SW1을 ON한다. SW2는 계속 ON이므로 목표가 약 40.97 RPM으로
   한 번의 switch edge에서 바뀐다.

```text
python3 tools/capture_telemetry.py --duration 30 --mark-after 8 \
  --output artifacts/experiments/step_27_to_41.csv
```

CSV를 MATLAB Drive의 프로젝트 `data` 폴더에 넣고 실행한다.

```matlab
metrics = ANALYZE_TELEMETRY('artifacts/experiments/step_27_to_41.csv');
```

최소 1초의 step 이전 구간과 3초 이상의 step 이후 구간을 확보한다. 생성되는 metrics CSV와 PNG를
`artifacts`에 보관한다.

## Open-loop system identification

Open-loop telemetry bitstream에서 SW0을 arm한 뒤 5초 간격으로 PWM duty를 25%, 37.5%, 50%,
37.5%, 25%로 바꾼다. 각 변경은 한 switch만 움직여 가능한 한 깨끗한 입력 edge를 만든다. 전체
30초 이상을 기록한다.

```text
python3 tools/capture_telemetry.py --duration 35 --mark-after 5 \
  --output artifacts/experiments/open_loop_identification.csv
```

MATLAB 기본 연산만 사용하는 1차+dead-time 식별을 실행한다.

```matlab
model = IDENTIFY_MOTOR('artifacts/experiments/open_loop_identification.csv');
```

보고값은 plant gain, time constant, dead time, RMSE, model fit과 IMC 기반 PI 후보 계수다. 후보 계수는
즉시 RTL에 적용하지 않고 기존 `Kp=0.9`, `Ki=6/s`와 simulation 및 실물 응답을 비교한 뒤 선택한다.

## 전원 외란 복원

목표를 SW2 약 27.32 RPM으로 유지하고 12 V 정상상태를 기록한다. 약 5초에 PSU를 9 V로 낮추고
10초에 12 V로 복원한다. current limit은 0.5 A를 유지한다. 배선은 변경하지 않는다.

```text
python3 tools/capture_telemetry.py --duration 20 --mark-after 5 --second-mark-after 10 \
  --output artifacts/experiments/disturbance.csv
```

```matlab
metrics = ANALYZE_DISTURBANCE('artifacts/experiments/disturbance.csv',5,10);
```

실제 전압 변경 시각은 영상 또는 실험 기록에 남긴다. 손으로 축을 누르는 방식은 부하가 정량적이지
않고 안전하지 않으므로 공식 결과로 사용하지 않는다.
