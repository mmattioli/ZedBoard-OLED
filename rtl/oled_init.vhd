--
-- Written by Ryan Kim, Digilent Inc.
-- Modified by Michael Mattioli
--
-- Description: Runs the initialization sequence for the OLED display.
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity oled_init is
    port (  clk         : in std_logic; -- System clock
            rst         : in std_logic; -- Global synchronous reset
            en          : in std_logic; -- Block enable pin
            sdout       : out std_logic; -- SPI data out
            oled_sclk   : out std_logic; -- SPI clock
            oled_dc     : out std_logic; -- Data/Command pin
            oled_res    : out std_logic; -- OLED reset
            oled_vbat   : out std_logic; -- oled_vbat enable
            oled_vdd    : out std_logic; -- oled_vdd enable
            fin         : out std_logic); -- Finish flag for block
end oled_init;

architecture behavioral of oled_init is

    component spi_ctrl
        port (  clk         : in std_logic;
                rst         : in std_logic;
                en          : in std_logic;
                sdata       : in std_logic_vector (7 downto 0);
                sdout       : out std_logic;
                oled_sclk   : out std_logic;
                fin         : out std_logic);
    end component;

    component delay
        port (  clk         : in std_logic;
                rst         : in std_logic;
                delay_ms    : in std_logic_vector (11 downto 0);
                delay_en    : in std_logic;
                delay_fin   : out std_logic);
    end component;

    type states is (Transition1,
                    Transition2,
                    Transition3,
                    Transition4,
                    Transition5,
                    Idle,
                    VddOn,
                    Wait1,
                    DispOff,
                    ResetOn,
                    Wait2,
                    ResetOff,
                    ChargePump1,
                    ChargePump2,
                    PreCharge1,
                    PreCharge2,
                    VbatOn,
                    Wait3,
                    DispContrast1,
                    DispContrast2,
                    InvertDisp1,
                    InvertDisp2,
                    ComConfig1,
                    ComConfig2,
                    DispOn,
                    FullDisp,
                    Done);

    signal current_state : states := Idle;
    signal after_state : states := Idle;

    signal temp_dc      : std_logic := '0';
    signal temp_res     : std_logic := '1';
    signal temp_vbat    : std_logic := '1';
    signal temp_vdd     : std_logic := '1';
    signal temp_fin     : std_logic := '0';

    signal temp_delay_ms    : std_logic_vector (11 downto 0) := (others => '0');
    signal temp_delay_en    : std_logic := '0';
    signal temp_delay_fin   : std_logic;
    signal temp_spi_en      : std_logic := '0';
    signal temp_sdata       : std_logic_vector (7 downto 0) := (others => '0');
    signal temp_spi_fin     : std_logic;

begin

    spi_comp: spi_ctrl port map (   clk => clk,
                                    rst => rst,
                                    en => temp_spi_en,
                                    sdata => temp_sdata,
                                    sdout => sdout,
                                    oled_sclk => oled_sclk,
                                    fin => temp_spi_fin);

    delay_comp: delay port map (clk => clk,
                                rst => rst,
                                delay_ms => temp_delay_ms,
                                delay_en => temp_delay_en,
                                delay_fin => temp_delay_fin);

    oled_dc <= temp_dc;
    oled_res <= temp_res;
    oled_vbat <= temp_vbat;
    oled_vdd <= temp_vdd;
    fin <= temp_fin;

    -- Delay 100 ms after VbatOn
    temp_delay_ms <=    "000001100100" when after_state = DispContrast1 else -- 100ms
                        "000000000001"; -- 1ms

    process (clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                current_state <= Idle;
                temp_res <= '0';
            else
                temp_res <= '1';
                case current_state is
                    when Idle =>
                        if en = '1' then
                            temp_dc <= '0';
                            current_state <= VddOn;
                        end if;

                    -- Initialization Sequence
                    -- This should be done everytime the OLED display is started
                    when VddOn =>
                        temp_vdd <= '0';
                        current_state <= Wait1;
                    when Wait1 =>
                        after_state <= DispOff;
                        current_state <= Transition3;
                    when DispOff =>
                        temp_sdata <= "10101110"; -- 0xAE
                        after_state <= ResetOn;
                        current_state <= Transition1;
                    when ResetOn =>
                        temp_res <= '0';
                        current_state <= Wait2;
                    when Wait2 =>
                        after_state <= ResetOff;
                        current_state <= Transition3;
                    when ResetOff =>
                        temp_res <= '1';
                        after_state <= ChargePump1;
                        current_state <= Transition3;
                    when ChargePump1 =>
                        temp_sdata <= "10001101"; -- 0x8D
                        after_state <= ChargePump2;
                        current_state <= Transition1;
                    when ChargePump2 =>
                        temp_sdata <= "00010100"; -- 0x14
                        after_state <= PreCharge1;
                        current_state <= Transition1;
                    when PreCharge1  =>
                        temp_sdata <= "11011001"; -- 0xD9
                        after_state <= PreCharge2;
                        current_state <= Transition1;
                    when PreCharge2 =>
                        temp_sdata <= "11110001"; -- 0xF1
                        after_state <= VbatOn;
                        current_state <= Transition1;
                    when VbatOn =>
                        temp_vbat <= '0';
                        current_state <= Wait3;
                    when Wait3 =>
                        after_state <= DispContrast1;
                        current_state <= Transition3;
                    when DispContrast1=>
                        temp_sdata <= "10000001"; -- 0x81
                        after_state <= DispContrast2;
                        current_state <= Transition1;
                    when DispContrast2=>
                        temp_sdata <= "00001111"; -- 0x0F
                        after_state <= InvertDisp1;
                        current_state <= Transition1;
                    when InvertDisp1 =>
                        temp_sdata <= "10100000"; -- 0xA0
                        after_state <= InvertDisp2;
                        current_state <= Transition1;
                    when InvertDisp2 =>
                        temp_sdata <= "11000000"; -- 0xC0
                        after_state <= ComConfig1;
                        current_state <= Transition1;
                    when ComConfig1 =>
                        temp_sdata <= "11011010"; -- 0xDA
                        after_state <= ComConfig2;
                        current_state <= Transition1;
                    when ComConfig2 =>
                        temp_sdata <= "00000000"; -- 0x00
                        after_state <= DispOn;
                        current_state <= Transition1;
                    when DispOn =>
                        temp_sdata <= "10101111"; -- 0xAF
                        after_state <= Done;
                        current_state <= Transition1;
                    -- End Initialization sequence

                    -- Used for debugging, turns the entire screen on regardless of memory
                    when FullDisp =>
                        temp_sdata <= "10100101"; -- 0xA5
                        after_state <= Done;
                        current_state <= Transition1;

                    -- Done state
                    when Done =>
                        if en = '0' then
                            temp_fin <= '0';
                            current_state <= Idle;
                        else
                            temp_fin <= '1';
                        end if;

                    -- SPI transitions
                    -- 1. Set en to 1
                    -- 2. Waits for spi_ctrl to finish
                    -- 3. Goes to clear state (Transition5)
                    when Transition1 =>
                        temp_spi_en <= '1';
                        current_state <= Transition2;
                    when Transition2 =>
                        if temp_spi_fin = '1' then
                            current_state <= Transition5;
                        end if;
                    -- End SPI transitions

                    -- Delay transitions
                    -- 1. Set delay_en to 1
                    -- 2. Waits for delay to finish
                    -- 3. Goes to Clear state (Transition5)
                    when Transition3 =>
                        temp_delay_en <= '1';
                        current_state <= Transition4;
                    when Transition4 =>
                        if temp_delay_fin = '1' then
                            current_state <= Transition5;
                        end if;
                    -- End delay transitions

                    -- Clear transitions
                    -- 1. Sets both delay_en and en to 0
                    -- 2. Go to after state
                    when Transition5 =>
                        temp_spi_en <= '0';
                        temp_delay_en <= '0';
                        current_state <= after_state;
                    -- End Clear transitions

                    when others =>
                        current_state <= Idle;
                end case;
            end if;
        end if;
    end process;

end behavioral;
