--
-- Written by Ryan Kim, Digilent Inc.
-- Modified by Michael Mattioli
--
-- Description: Runs the initialization sequence for the PmodOLED.
--

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity OledInit is
    Port ( CLK     : in  STD_LOGIC; --System Clock
        RST     : in    STD_LOGIC;        --Global Synchronous Reset
        EN        : in  STD_LOGIC;        --Block enable pin
        CS      : out STD_LOGIC;        --SPI Chip Select
        SDO    : out STD_LOGIC;        --SPI data out
        SCLK    : out STD_LOGIC;        --SPI Clock
        DC        : out STD_LOGIC;        --Data/Command Pin
        RES    : out STD_LOGIC;        --PmodOLED RES
        VBAT    : out STD_LOGIC;        --VBAT enable
        VDD    : out STD_LOGIC;        --VDD enable
        FIN  : out STD_LOGIC);        --OledInit Finish Flag
end OledInit;

architecture Behavioral of OledInit is

COMPONENT SpiCtrl
    PORT(
         CLK : IN  std_logic;
         RST : IN  std_logic;
         SPI_EN : IN  std_logic;
         SPI_DATA : IN  std_logic_vector(7 downto 0);
         CS : OUT  std_logic;
         SDO : OUT  std_logic;
         SCLK : OUT  std_logic;
         SPI_FIN : OUT  std_logic
        );
    END COMPONENT;

COMPONENT Delay
    PORT(
         CLK : IN  std_logic;
         RST : IN  std_logic;
         DELAY_MS : IN  std_logic_vector(11 downto 0);
         DELAY_EN : IN  std_logic;
         DELAY_FIN : OUT  std_logic
        );
    END COMPONENT;

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
                    Done
                    );

signal current_state : states := Idle;
signal after_state : states := Idle;

signal temp_dc : STD_LOGIC := '0';
signal temp_res : STD_LOGIC := '1';
signal temp_vbat : STD_LOGIC := '1';
signal temp_vdd : STD_LOGIC := '1';
signal temp_fin : STD_LOGIC := '0';

signal temp_delay_ms : STD_LOGIC_VECTOR (11 downto 0) := (others => '0');
signal temp_delay_en : STD_LOGIC := '0';
signal temp_delay_fin : STD_LOGIC;
signal temp_spi_en : STD_LOGIC := '0';
signal temp_spi_data : STD_LOGIC_VECTOR (7 downto 0) := (others => '0');
signal temp_spi_fin : STD_LOGIC;

begin

 SPI_COMP: SpiCtrl PORT MAP (
          CLK => CLK,
          RST => RST,
          SPI_EN => temp_spi_en,
          SPI_DATA => temp_spi_data,
          CS => CS,
          SDO => SDO,
          SCLK => SCLK,
          SPI_FIN => temp_spi_fin
        );

   DELAY_COMP: Delay PORT MAP (
          CLK => CLK,
          RST => RST,
          DELAY_MS => temp_delay_ms,
          DELAY_EN => temp_delay_en,
          DELAY_FIN => temp_delay_fin
        );

DC <= temp_dc;
RES <= temp_res;
VBAT <= temp_vbat;
VDD <= temp_vdd;
FIN <= temp_fin;

--Delay 100 ms after VbatOn
temp_delay_ms <= "000001100100" when (after_state = DispContrast1) else --100 ms
                 "000000000001"; --1ms

    STATE_MACHINE : process (CLK)
    begin
        if(rising_edge(CLK)) then
            if(RST = '1') then
                current_state <= Idle;
                temp_res <= '0';
            else
                temp_res <= '1';
                case (current_state) is
                    when Idle             =>
                        if(EN = '1') then
                            temp_dc <= '0';
                            current_state <= VddOn;
                        end if;

                    --Initialization Sequence
                    --This should be done everytime the PmodOLED is started
                    when VddOn             =>
                        temp_vdd <= '0';
                        current_state <= Wait1;
                    when Wait1             =>
                        after_state <= DispOff;
                        current_state <= Transition3;
                    when DispOff         =>
                        temp_spi_data <= "10101110"; --0xAE
                        after_state <= ResetOn;
                        current_state <= Transition1;
                    when ResetOn        =>
                        temp_res <= '0';
                        current_state <= Wait2;
                    when Wait2            =>
                        after_state <= ResetOff;
                        current_state <= Transition3;
                    when ResetOff        =>
                        temp_res <= '1';
                        after_state <= ChargePump1;
                        current_state <= Transition3;
                    when ChargePump1    =>
                        temp_spi_data <= "10001101"; --0x8D
                        after_state <= ChargePump2;
                        current_state <= Transition1;
                    when ChargePump2     =>
                        temp_spi_data <= "00010100"; --0x14
                        after_state <= PreCharge1;
                        current_state <= Transition1;
                    when PreCharge1    =>
                        temp_spi_data <= "11011001"; --0xD9
                        after_state <= PreCharge2;
                        current_state <= Transition1;
                    when PreCharge2    =>
                        temp_spi_data <= "11110001"; --0xF1
                        after_state <= VbatOn;
                        current_state <= Transition1;
                    when VbatOn            =>
                        temp_vbat <= '0';
                        current_state <= Wait3;
                    when Wait3            =>
                        after_state <= DispContrast1;
                        current_state <= Transition3;
                    when DispContrast1=>
                        temp_spi_data <= "10000001"; --0x81
                        after_state <= DispContrast2;
                        current_state <= Transition1;
                    when DispContrast2=>
                        temp_spi_data <= "00001111"; --0x0F
                        after_state <= InvertDisp1;
                        current_state <= Transition1;
                    when InvertDisp1    =>
                        temp_spi_data <= "10100001"; --0xA1
                        after_state <= InvertDisp2;
                        current_state <= Transition1;
                    when InvertDisp2 =>
                        temp_spi_data <= "11001000"; --0xC8
                        after_state <= ComConfig1;
                        current_state <= Transition1;
                    when ComConfig1    =>
                        temp_spi_data <= "11011010"; --0xDA
                        after_state <= ComConfig2;
                        current_state <= Transition1;
                    when ComConfig2     =>
                        temp_spi_data <= "00100000"; --0x20
                        after_state <= DispOn;
                        current_state <= Transition1;
                    when DispOn            =>
                        temp_spi_data <= "10101111"; --0xAF
                        after_state <= Done;
                        current_state <= Transition1;
                    --END Initialization sequence

                    --Used for debugging, This command turns the entire screen on regardless of memory
                    when FullDisp        =>
                        temp_spi_data <= "10100101"; --0xA5
                        after_state <= Done;
                        current_state <= Transition1;

                    --Done state
                    when Done            =>
                        if(EN = '0') then
                            temp_fin <= '0';
                            current_state <= Idle;
                        else
                            temp_fin <= '1';
                        end if;

                    --SPI transitions
                    --1. Set SPI_EN to 1
                    --2. Waits for SpiCtrl to finish
                    --3. Goes to clear state (Transition5)
                    when Transition1 =>
                        temp_spi_en <= '1';
                        current_state <= Transition2;
                    when Transition2 =>
                        if(temp_spi_fin = '1') then
                            current_state <= Transition5;
                        end if;

                    --Delay Transitions
                    --1. Set DELAY_EN to 1
                    --2. Waits for Delay to finish
                    --3. Goes to Clear state (Transition5)
                    when Transition3 =>
                        temp_delay_en <= '1';
                        current_state <= Transition4;
                    when Transition4 =>
                        if(temp_delay_fin = '1') then
                            current_state <= Transition5;
                        end if;

                    --Clear transition
                    --1. Sets both DELAY_EN and SPI_EN to 0
                    --2. Go to after state
                    when Transition5 =>
                        temp_spi_en <= '0';
                        temp_delay_en <= '0';
                        current_state <= after_state;
                    --END SPI transitions
                    --END Delay Transitions
                    --END Clear transition

                    when others         =>
                        current_state <= Idle;
                end case;
            end if;
        end if;
    end process;

end Behavioral;
