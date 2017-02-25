--
-- Written by Ryan Kim, Digilent Inc.
-- Modified by Michael Mattioli
--
-- Description: Top level controller that controls the PmodOLED blocks.
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity oled_ctrl is
    port (  clk     : in std_logic;
            rst     : in std_logic;
            sdin    : out std_logic;
            sclk    : out std_logic;
            dc      : out std_logic;
            res     : out std_logic;
            vbat    : out std_logic;
            vdd     : out std_logic);
end oled_ctrl;

architecture behavioral of oled_ctrl is

    component oled_init is
        port (  clk     : in std_logic;
                rst     : in std_logic;
                en      : in std_logic;
                sdo     : out std_logic;
                sclk    : out std_logic;
                dc      : out std_logic;
                res     : out std_logic;
                vbat    : out std_logic;
                vdd     : out std_logic;
                fin     : out std_logic);
    end component;

    component oled_ex is
        port (  clk     : in std_logic;
                rst     : in std_logic;
                en      : in std_logic;
                sdo     : out std_logic;
                sclk    : out std_logic;
                dc      : out std_logic;
                fin     : out std_logic);
    end component;

    type states is (Idle, OledInitialize, OledExample, Done);

    signal current_state : states := Idle;

    signal init_en          : std_logic := '0';
    signal init_done        : std_logic;
    signal init_sdo         : std_logic;
    signal init_sclk        : std_logic;
    signal init_dc          : std_logic;

    signal example_en       : std_logic := '0';
    signal example_sdo      : std_logic;
    signal example_sclk     : std_logic;
    signal example_dc       : std_logic;
    signal example_done     : std_logic;

begin

    Initialize: oled_init port map (clk,
                                    rst,
                                    init_en,
                                    init_sdo,
                                    init_sclk,
                                    init_dc,
                                    res,
                                    vbat,
                                    vdd,
                                    init_done);

    Example: oled_ex port map ( clk,
                                rst,
                                example_en,
                                example_sdo,
                                example_sclk,
                                example_dc,
                                example_done);

    -- MUXes to indicate which outputs are routed out depending on which block is enabled
    sdin <= init_sdo when current_state = OledInitialize else example_sdo;
    sclk <= init_sclk when current_state = OledInitialize else example_sclk;
    dc <= init_dc when current_state = OledInitialize else example_dc;
    --END output MUXes

    -- MUXes that enable blocks when in the proper states
    init_en <= '1' when current_state = OledInitialize else '0';
    example_en <= '1' when current_state = OledExample else '0';
    -- END enable MUXes

    process (clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                current_state <= Idle;
            else
                case current_state is
                    when Idle =>
                        current_state <= OledInitialize;
                    -- Go through the initialization sequence
                    when OledInitialize =>
                        if init_done = '1' then
                            current_state <= OledExample;
                        end if;
                    -- Do example and do nothing when finished
                    when OledExample =>
                        if example_done = '1' then
                            current_state <= Done;
                        end if;
                    -- Do Nothing
                    when Done =>
                        current_state <= Done;
                    when others =>
                        current_state <= Idle;
                end case;
            end if;
        end if;
    end process;

end behavioral;
