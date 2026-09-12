# Project07_MotorControl

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
| MATLAB/Simulink | 기준 모델 closed-loop PASS, 다음 closed-loop build 전 현재 소스로 재실행 필요 |
| XSim | open-loop commissioning PASS |
| Vivado 2024.2 open-loop timing | setup +3.142 ns, hold +0.122 ns |
| Open-loop 구현 자원 | LUT 84, FF 180, DSP 1, BRAM 0 |
| DRC Error | 0 |
| JGB37-520 단독 구동 | 3.0 V, 0.09~0.11 A, CW PASS |
| Encoder C1 | 3.3 V 공급, 342~354 Hz 사각파 확인 |

현재 `artifacts/laplace.bit`은 안전한 `internal` 모드다. 외부 출력은 LOW이며 실제 모터 구동용
bitstream이 아니다. 엔코더 환산값과 모터 응답을 측정한 뒤 open-loop, closed-loop 순서로 진행한다.
실물 측정의 조건과 남은 항목은 [docs/HARDWARE_TEST_RESULTS.md](docs/HARDWARE_TEST_RESULTS.md)에 있다.
현재 `vivado/laplace_config.tcl`은 다음 실물 시험을 위해 `open_loop`로 설정되어 있다.

실제 open-loop 측정에는 `artifacts/laplace_open_loop.bit`을 사용한다. 이 파일은 XSim과 Vivado
2024.2 timing/DRC를 통과했으며 SHA-256은
`9bf58f6bfcd1f406bce613ec3f392c37465ec6198ddfbca1cf6781a89c0a8157`이다.

## 실행

MATLAB Online:

```matlab
cd Project07_MotorControl
RUN_MATLAB_CHECKS
```

PC와 Vivado 2024.2:

```text
python3 -m pip install -r requirements.txt
python3 tools/offline_check.py
python3 tools/run.py sim
python3 tools/run.py build
```

L298N 배선과 PWM만 확인하는 open-loop commissioning은 PID/plant MATLAB 모델을 사용하지 않는다.
MATLAB Online을 사용할 수 없을 때는 다음 두 단계만 실행한다.

```text
python3 tools/run.py open-loop-sim
python3 tools/run.py open-loop-build
```

이 경로는 `tb_laplace_motor`가 PWM, IN1/IN2, arm, reset과 stall 차단을 통과해야 bitstream을 만든다.
PID closed-loop build에는 기존 MATLAB과 전체 XSim gate가 계속 필요하다.

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
| `artifacts` | 내부/open-loop bitstream, 구현 보고서, MATLAB 입력과 결과 |
| `HANDOFF.md` | 다음 작업자가 먼저 읽을 진행 기록 |

실물 구동 전에는 [docs/HARDWARE.md](docs/HARDWARE.md)를 확인한다.
