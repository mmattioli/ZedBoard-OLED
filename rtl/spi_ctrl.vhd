--
-- Written by Ryan Kim, Digilent Inc.
-- Modified by Michael Mattioli
--
-- Description: SPI block that sends SPI data formatted oled_sclk active low with sdout changing
-- on the falling edge.
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity spi_ctrl is
    Port ( clk          : in std_logic; -- System clok (100MHz)
           rst          : in std_logic; -- Global synchronous reset
           en           : in std_logic; -- Block enable pin
           sdata        : in std_logic_vector (7 downto 0); -- Byte to be sent
           sdout        : out std_logic; -- Serial data out
           oled_sclk    : out std_logic; -- OLED serial clock
           fin          : out std_logic); -- Finish flag for block
end spi_ctrl;

architecture behavioral of spi_ctrl is

    type states is (Idle, Send, Done);

    signal current_state : states := Idle; -- Signal for state machine

    signal shift_register   : std_logic_vector (7 downto 0); -- Shift register to shift out sdata saved when en was set
    signal shift_counter    : std_logic_vector (3 downto 0); -- Keeps track how many bits were sent
    signal clk_divided      : std_logic := '1'; -- Used as oled_sclk
    signal counter          : std_logic_vector (4 downto 0) := (others => '0'); -- Count clocks to be used to divide clk
    signal temp_sdata       : std_logic := '1'; -- Tied to sdout

    signal falling : std_logic := '0'; -- Signal indicating that the clk has just fell

begin

    clk_divided <= not counter(4); -- oled_sclk = clk / 32
    oled_sclk <= clk_divided;
    sdout <= temp_sdata;
    fin <= '1' when current_state = Done else '0';

    state_machine : process (clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then -- Synchronous rst
                current_state <= Idle;
            else
                case current_state is
                    when Idle => -- Wait for en to go high
                        if en = '1' then
                            current_state <= Send;
                        end if;
                    when Send => -- Start sending bits, transition out when all bits are sent and oled_sclk is high
                        if shift_counter = "1000" and falling = '0' then
                            current_state <= Done;
                        end if;
                    when Done => -- Finish SPI transimission wait for en to go low
                        if en = '0' then
                            current_state <= Idle;
                        end if;
                    when others =>
                        current_state <= Idle;
                end case;
            end if;
        end if;
    end process state_machine;

    clk_div : process (clk)
    begin
        if rising_edge(clk) then
            if current_state = Send then -- Start clock counter when in send state
                counter <= counter + 1;
            else -- Reset clock counter when not in send state
                counter <= (others => '0');
            end if;
        end if;
    end process clk_div;

    spi_send_byte : process (clk) -- Sends SPI data formatted oled_sclk active low with sdout changing on the falling edge
    begin
        if rising_edge(clk) then
            if current_state = Idle then
                shift_counter <= (others => '0');
                shift_register <= sdata; -- Keeps placing sdata into shift_register so that when state goes to send it has the latest sdata
                temp_sdata <= '1';
            elsif current_state = Send then
                if clk_divided = '0' and falling = '0' then -- If on the falling edge of clk_divided
                    falling <= '1'; -- Indicate that it is passed the falling edge
                    temp_sdata <= shift_register(7); -- Send out the MSB
                    shift_register <= shift_register(6 downto 0) & '0'; -- Shift through sdata
                    shift_counter <= shift_counter + 1; -- Keep track of what bit it is on
                elsif clk_divided = '1' then -- On oled_sclk high reset the falling flag
                    falling <= '0';
                end if;
            end if;
        end if;
    end process spi_send_byte;

end behavioral;
