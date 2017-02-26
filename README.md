# ZedBoard OLED Display

## About

The goal of this project is to implement a design which drives the OLED display on the
[ZedBoard][ZedBoard Product Page] using the
[Xilinx Vivado Design Suite][Xilinx Vivado Design Suite]. The current design is implemented purely
on the Zynq PL by modifying a sample
[ISE project supplied by Digilent][Digilent Pmod OLED Resource Center].

## Getting started

After you've cloned the repo and built the project:

  1. Run the synthesis and implementation
  2. Generate a bitstream
  3. Program the FPGA

The display should be initially be filled with letters, numbers, and characters and then transition
to "Hello world!" on the very first line as such:

```
  ----------------
| Hello world!     |
|                  |
|                  |
|                  |
  ----------------
```

## Further information

See the [wiki](https://github.com/mmattioli/ZedBoard-OLED/wiki) for further information and
documentation.

[ZedBoard Product Page]: http://zedboard.org/product/zedboard
[Xilinx Vivado Design Suite]: http://www.xilinx.com/products/design-tools/vivado.html
[Digilent Pmod OLED Resource Center]: http://store.digilentinc.com/pmod-oled-128-x-32-pixel-monochromatic-oled-display/
