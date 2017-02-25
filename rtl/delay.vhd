--
-- Written by Ryan Kim, Digilent Inc.
-- Modified by Michael Mattioli
--
-- Description: Creates a delay of delay_ms ms.
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity delay is
    port (  clk         : in std_logic; -- System clk
            rst         : in std_logic;  -- Global rst (Synchronous)
            delay_ms    : in std_logic_vector (11 downto 0); -- Amount of ms to delay
            delay_en    : in std_logic; -- Delay block enable
            delay_fin   : out std_logic); -- Delay finish flag
end delay;

architecture behavioral of delay is

    type states is (Idle, Hold, Done);

    signal current_state : states := Idle; -- Signal for state machine
    signal clk_counter : std_logic_vector(16 downto 0) := (others => '0'); -- Counts up on every rising edge of clk
    signal ms_counter : std_logic_vector (11 downto 0) := (others => '0'); -- Counts up when clk_counter = 100,000

begin
    -- delay_fin goes high when delay is done
    delay_fin <= '1' when (current_state = Done and delay_en = '1') else '0';

    -- State machine for Delay block
    state_machine : process (clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then -- When rst is asserted switch to Idle (synchronous)
                current_state <= Idle;
            else
                case current_state is
                    when Idle =>
                        if delay_en = '1' then -- Start delay on delay_en
                            current_state <= Hold;
                        end if;
                    when Hold =>
                        if ms_counter = delay_ms then -- Stay until delay_ms has occured
                            current_state <= Done;
                        end if;
                    when Done =>
                        if delay_en = '0' then -- Wait until delay_en is deasserted to go to Idle
                            current_state <= Idle;
                        end if;
                    when others =>
                        current_state <= Idle;
                end case;
            end if;
        end if;
    end process;


    -- Creates ms_counter that counts at 1KHz
    clk_div : process (clk)
    begin
        if rising_edge(clk) then
            if current_state = Hold then
                if clk_counter = "11000011010100000" then -- 100,000
                    clk_counter <= (others => '0');
                    ms_counter <= ms_counter + 1; -- Increments at 1KHz
                else
                    clk_counter <= clk_counter + 1;
                end if;
            else -- If not in the hold state reset counters
                clk_counter <= (others => '0');
                ms_counter <= (others => '0');
            end if;
        end if;
    end process;

end behavioral;
