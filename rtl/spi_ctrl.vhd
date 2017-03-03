--
-- Written by Ryan Kim, Digilent Inc.
-- Modified by Michael Mattioli
--
-- Description: SPI block that sends SPI data formatted sclk active low with sdo changing on the
-- falling edge.
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity spi_ctrl is
    Port ( clk          : in std_logic; -- System clk (100MHz)
           rst          : in std_logic; -- Global rst (Synchronous)
           spi_en       : in std_logic; -- SPI block enable pin
           spi_data     : in std_logic_vector (7 downto 0); -- Byte to be sent
           sdo          : out std_logic; -- SPI data out
           sclk         : out std_logic; -- SPI clock
           spi_fin      : out std_logic); --SPI finish flag
end spi_ctrl;

architecture behavioral of spi_ctrl is

    type states is (Idle,
                    Send,
                    Done);

    signal current_state : states := Idle; -- Signal for state machine

    signal shift_register   : std_logic_vector (7 downto 0); -- Shift register to shift out spi_data saved when spi_en was set
    signal shift_counter    : std_logic_vector (3 downto 0); -- Keeps track how many bits were sent
    signal clk_divided      : std_logic := '1'; -- Used as sclk
    signal counter          : std_logic_vector (4 downto 0) := (others => '0'); -- Count clocks to be used to divide clk
    signal temp_sdo         : std_logic := '1'; -- Tied to sdo

    signal falling : std_logic := '0'; -- Signal indicating that the clk has just fell

begin

    clk_divided <= not counter(4); -- sclk = clk / 32
    sclk <= clk_divided;
    sdo <= temp_sdo;
    spi_fin <= '1' when current_state = Done else '0';

    STATE_MACHINE : process (clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then -- Synchronous rst
                current_state <= Idle;
            else
                case current_state is
                    when Idle => -- Wait for spi_en to go high
                        if spi_en = '1' then
                            current_state <= Send;
                        end if;
                    when Send => -- Start sending bits, transition out when all bits are sent and sclk is high
                        if shift_counter = "1000" and falling = '0' then
                            current_state <= Done;
                        end if;
                    when Done => -- Finish SPI transimission wait for spi_en to go low
                        if spi_en = '0' then
                            current_state <= Idle;
                        end if;
                    when others =>
                        current_state <= Idle;
                end case;
            end if;
        end if;
    end process;

    clk_div : process (clk)
    begin
        if rising_edge(clk) then
            if current_state = Send then -- Start clock counter when in send state
                counter <= counter + 1;
            else -- Reset clock counter when not in send state
                counter <= (others => '0');
            end if;
        end if;
    end process;

    spi_send_byte : process (clk) -- Sends SPI data formatted sclk active low with sdo changing on the falling edge
    begin
        if rising_edge(clk) then
            if current_state = Idle then
                shift_counter <= (others => '0');
                shift_register <= spi_data; -- Keeps placing spi_data into shift_register so that when state goes to send it has the latest spi_data
                temp_sdo <= '1';
            elsif current_state = Send then
                if clk_divided = '0' and falling = '0' then -- If on the falling edge of Clk_divided
                    falling <= '1'; -- Indicate that it is passed the falling edge
                    temp_sdo <= shift_register(7); -- Send out the MSB
                    shift_register <= shift_register(6 downto 0) & '0'; -- Shift through spi_data
                    shift_counter <= shift_counter + 1; -- Keep track of what bit it is on
                elsif clk_divided = '1' then -- On sclk high reset the falling flag
                    falling <= '0';
                end if;
            end if;
        end if;
    end process;

end behavioral;
