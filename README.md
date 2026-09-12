# Project08_MotorControl

Basys3에서 DC 모터 전달함수를 이산화하고 고정소수점 PID와 PWM을 Pure RTL로 구현하는
학부 포트폴리오 프로젝트다. FPGA에서 Laplace transform을 실시간 계산하는 구조가 아니라,
MATLAB에서 만든 연속시간 모델과 제어기를 이산화해 RTL 제어기로 구현한다.

## 구조

```text
reference -> error -> fixed-point PID -> saturation -> 20 kHz PWM -> L298N -> motor
                         ^                                      |
                         +------------- Hall encoder C1 --------+
```

- Basys3, MicroBlaze 미사용
- 100 Hz PID, 20 kHz PWM
- Q16.16 계수와 64-bit 중간 곱셈
- 출력 saturation과 integral anti-windup
- 내부 test plant, 외부 open-loop, 외부 closed-loop 모드
- 직접 작성한 Verilog-2001, HDL Coder 미사용

## 현재 검증 결과

| 항목 | 결과 |
|---|---:|
| MATLAB/Simulink | closed-loop PASS |
| XSim | 5개 testbench PASS |
| Vivado 2024.2 timing | setup +0.219 ns, hold +0.122 ns |
| 구현 자원 | LUT 448, FF 348, DSP 6, BRAM 0 |
| DRC Error | 0 |

현재 `artifacts/laplace.bit`은 안전한 `internal` 모드다. 외부 출력은 LOW이며 실제 모터 구동용
bitstream이 아니다. 엔코더 환산값과 모터 응답을 측정한 뒤 open-loop, closed-loop 순서로 진행한다.

## 실행

MATLAB Online:

```matlab
cd Project08_MotorControl
RUN_MATLAB_CHECKS
```

PC와 Vivado 2024.2:

```text
python3 -m pip install -r requirements.txt
python3 tools/offline_check.py
python3 tools/run.py sim
python3 tools/run.py build
```

외부 모드를 빌드하려면 [vivado/laplace_config.tcl](vivado/laplace_config.tcl)을 수정한다. 설정 변경은
소스 해시를 바꾸므로 MATLAB과 XSim을 다시 실행해야 한다.

## 폴더

| 경로 | 내용 |
|---|---|
| `laplace/rtl` | PID, plant, encoder, PWM, Basys3 top |
| `laplace/tb` | 자동 PASS/FAIL testbench 5개 |
| `data` | PID 계수와 1,200-step 기준값 |
| `matlab` | 전달함수, 정수 Golden, Simulink 함수 |
| `vivado` | 프로젝트 생성, XSim, bitstream Tcl |
| `artifacts` | 내부 모드 bitstream, 보고서, MATLAB 결과 |
| `HANDOFF.md` | 다음 작업자가 먼저 읽을 진행 기록 |

실물 구동 전에는 [docs/HARDWARE.md](docs/HARDWARE.md)를 확인한다.

