--
-- Written by Ryan Kim, Digilent Inc.
-- Modified by Michael Mattioli
--
-- Description: Creates a delay of DELAY_MS ms.
--

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity Delay is
    Port ( CLK             : in  STD_LOGIC; --System CLK
            RST         : in STD_LOGIC;  --Global RST (Synchronous)
            DELAY_MS     : in  STD_LOGIC_VECTOR (11 downto 0); --Amount of ms to delay
            DELAY_EN     : in  STD_LOGIC; --Delay block enable
            DELAY_FIN     : out  STD_LOGIC); --Delay finish flag
end Delay;

architecture Behavioral of Delay is

type states is (Idle,
                Hold,
                Done);

signal current_state : states := Idle; --Signal for state machine
signal clk_counter : STD_LOGIC_VECTOR(16 downto 0) := (others => '0'); --Counts up on every rising edge of CLK
signal ms_counter : STD_LOGIC_VECTOR (11 downto 0) := (others => '0'); --Counts up when clk_counter = 100,000

begin
    --DELAY_FIN goes HIGH when delay is done
    DELAY_FIN <= '1' when (current_state = Done and DELAY_EN = '1') else
                    '0';

    --State machine for Delay block
    STATE_MACHINE : process (CLK)
    begin
        if(rising_edge(CLK)) then
            if(RST = '1') then --When RST is asserted switch to idle (synchronous)
                current_state <= Idle;
            else
                case (current_state) is
                    when Idle =>
                        if(DELAY_EN = '1') then --Start delay on DELAY_EN
                            current_state <= Hold;
                        end if;
                    when Hold =>
                        if( ms_counter = DELAY_MS) then --stay until DELAY_MS has occured
                            current_state <= Done;
                        end if;
                    when Done =>
                        if(DELAY_EN = '0') then --Wait til DELAY_EN is deasserted to go to IDLE
                            current_state <= Idle;
                        end if;
                    when others =>
                        current_state <= Idle;
                end case;
            end if;
        end if;
    end process;


    --Creates ms_counter that counts at 1KHz
    CLK_DIV : process (CLK)
    begin
        if(CLK'event and CLK = '1') then
            if (current_state = Hold) then
                if(clk_counter = "11000011010100000") then --100,000
                    clk_counter <= (others => '0');
                    ms_counter <= ms_counter + 1; --increments at 1KHz
                else
                    clk_counter <= clk_counter + 1;
                end if;
            else --If not in the hold state reset counters
                clk_counter <= (others => '0');
                ms_counter <= (others => '0');
            end if;
        end if;
    end process;

end Behavioral;
