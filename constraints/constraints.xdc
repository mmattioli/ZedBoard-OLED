set_property PACKAGE_PIN Y9 [get_ports {CLK}];  # "GCLK"
create_clock -period 100.000 -name CLK -waveform {0.000 50.000} [get_ports CLK]

set_property PACKAGE_PIN U10  [get_ports {DC}];  # "OLED-DC"
set_property PACKAGE_PIN U9   [get_ports {RES}];  # "OLED-RES"
set_property PACKAGE_PIN AB12 [get_ports {SCLK}];  # "OLED-SCLK"
set_property PACKAGE_PIN AA12 [get_ports {SDIN}];  # "OLED-SDIN"
set_property PACKAGE_PIN U11  [get_ports {VBAT}];  # "OLED-VBAT"
set_property PACKAGE_PIN U12  [get_ports {VDD}];  # "OLED-VDD"

set_property PACKAGE_PIN P16 [get_ports {RST}];  # "BTNC"

set_property IOSTANDARD LVCMOS18 [get_ports -of_objects [get_iobanks 34]];
set_property IOSTANDARD LVCMOS33 [get_ports -of_objects [get_iobanks 13]];