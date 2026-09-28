# Tang Nano 20K + Nextion UART

Standalone VHDL UART project for sending text to a **Nextion HMI display** and receiving button/event commands with a **Tang Nano 20K** FPGA.

This repository contains the UART/Nextion part extracted from a larger ADS1115 + ACS712 + Nextion measurement project.

## Features

- Tang Nano 20K, 27 MHz system clock
- UART **9600 baud, 8N1**
- FPGA -> Nextion text update
- Nextion -> FPGA one-byte command reception
- Standard Nextion command termination with `FF FF FF`
- Example display object: `t1`
- Example received commands: `B1`, `B2`, `B3`, `43`
- LED indicators for TX activity and received commands

## Project Structure

```text
.
├── constraints/
│   └── tang_nano20k.cst
├── src/
│   ├── uart_rx.vhd
│   ├── uart_tx.vhd
│   └── nextion_demo_top.vhd
├── .gitignore
└── README.md
```

## Wiring

| Signal | Tang Nano 20K | Nextion |
|---|---:|---|
| `nextion_tx` | IO73 | RX |
| `nextion_rx` | IO77 | TX |
| GND | GND | GND |
| `clk` | IO4 | On-board 27 MHz clock |
| `reset_btn` | IO88 | On-board S1 button |

**Important:** Tang Nano 20K FPGA I/O is 3.3 V. Verify the UART logic voltage of your specific Nextion module. If its TX voltage can exceed the FPGA input rating, use proper level shifting.

## Nextion Editor Setup

Create a text component on `page0` with object name:

```text
t1
```

The FPGA periodically sends commands in this form:

```text
t1.txt="0000"
```

Every Nextion command is followed by:

```text
FF FF FF
```

## Sending Commands from Nextion to FPGA

Example button event commands in the Nextion Editor:

```text
printh B1
```

```text
printh B2
```

```text
printh B3
```

```text
printh 43
```

The example top-level uses these bytes as follows:

| Byte | Demo action |
|---|---|
| `B1` | Reset display counter and latch LED2 |
| `B2` | Latch LED3 |
| `B3` | Latch LED4 |
| `43` | Latch LED5 |

These command values match the command bytes used in the original measurement project.

## LED Meaning

Tang Nano LEDs are active-low.

| LED | Meaning |
|---|---|
| LED0 | UART transmit sequence active |
| LED1 | UART receive pulse |
| LED2 | `B1` has been received |
| LED3 | `B2` has been received |
| LED4 | `B3` has been received |
| LED5 | `43` has been received |

## Gowin EDA Setup

1. Create a new Tang Nano 20K project in Gowin EDA.
2. Add `src/uart_rx.vhd`.
3. Add `src/uart_tx.vhd`.
4. Add `src/nextion_demo_top.vhd`.
5. Set `nextion_demo_top` as the top-level entity.
6. Add `constraints/tang_nano20k.cst`.
7. Run synthesis, place & route and generate the bitstream.
8. Program the FPGA and connect the Nextion UART lines with a common ground.
