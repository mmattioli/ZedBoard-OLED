--
-- Written by Ryan Kim, Digilent Inc.
-- Modified by Michael Mattioli
--
-- Description: SPI block that sends SPI data formatted SCLK active low with SDO changing on the
-- falling edge.
--

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity SpiCtrl is
    Port ( CLK         : in  STD_LOGIC; --System CLK (100MHz)
           RST         : in  STD_LOGIC; --Global RST (Synchronous)
           SPI_EN     : in  STD_LOGIC; --SPI block enable pin
           SPI_DATA : in  STD_LOGIC_VECTOR (7 downto 0); --Byte to be sent
           CS        : out STD_LOGIC; --Chip Select
           SDO         : out STD_LOGIC; --SPI data out
           SCLK     : out STD_LOGIC; --SPI clock
           SPI_FIN    : out STD_LOGIC);--SPI finish flag
end SpiCtrl;

architecture Behavioral of SpiCtrl is

type states is (Idle,
                Send,
                Hold1,
                Hold2,
                Hold3,
                Hold4,
                Done);

signal current_state : states := Idle; --Signal for state machine

signal shift_register    : STD_LOGIC_VECTOR(7 downto 0); --Shift register to shift out SPI_DATA saved when SPI_EN was set
signal shift_counter     : STD_LOGIC_VECTOR(3 downto 0); --Keeps track how many bits were sent
signal clk_divided         : STD_LOGIC := '1'; --Used as SCLK
signal counter             : STD_LOGIC_VECTOR(4 downto 0) := (others => '0'); --Count clocks to be used to divide CLK
signal temp_sdo            : STD_LOGIC := '1'; --Tied to SDO

signal falling : STD_LOGIC := '0'; --signal indicating that the clk has just fell
begin
    clk_divided <= not counter(4); --SCLK = CLK / 32
    SCLK <= clk_divided;
    SDO <= temp_sdo;
    CS <= '1' when (current_state = Idle and SPI_EN = '0') else
        '0';
    SPI_FIN <= '1' when (current_state = Done) else
            '0';

    STATE_MACHINE : process (CLK)
    begin
        if(rising_edge(CLK)) then
            if(RST = '1') then --Synchronous RST
                current_state <= Idle;
            else
                case (current_state) is
                    when Idle => --Wait for SPI_EN to go high
                        if(SPI_EN = '1') then
                            current_state <= Send;
                        end if;
                    when Send => --Start sending bits, transition out when all bits are sent and SCLK is high
                        if(shift_counter = "1000" and falling = '0') then
                            current_state <= Hold1;
                        end if;
                    when Hold1 => --Hold CS low for a bit
                        current_state <= Hold2;
                    when Hold2 => --Hold CS low for a bit
                        current_state <= Hold3;
                    when Hold3 => --Hold CS low for a bit
                        current_state <= Hold4;
                    when Hold4 => --Hold CS low for a bit
                        current_state <= Done;
                    when Done => --Finish SPI transimission wait for SPI_EN to go low
                        if(SPI_EN = '0') then
                            current_state <= Idle;
                        end if;
                    when others =>
                        current_state <= Idle;
                end case;
            end if;
        end if;
    end process;

    CLK_DIV : process (CLK)
    begin
        if(rising_edge(CLK)) then
            if (current_state = Send) then --start clock counter when in send state
                counter <= counter + 1;
            else --reset clock counter when not in send state
                counter <= (others => '0');
            end if;
        end if;
    end process;

    SPI_SEND_BYTE : process (CLK) --sends SPI data formatted SCLK active low with SDO changing on the falling edge
    begin
        if(CLK'event and CLK = '1') then
            if(current_state = Idle) then
                shift_counter <= (others => '0');
                shift_register <= SPI_DATA; --keeps placing SPI_DATA into shift_register so that when state goes to send it has the latest SPI_DATA
                temp_sdo <= '1';
            elsif(current_state = Send) then
                if( clk_divided = '0' and falling = '0') then --if on the falling edge of Clk_divided
                    falling <= '1'; --Indicate that it is passed the falling edge
                    temp_sdo <= shift_register(7); --send out the MSB
                    shift_register <= shift_register(6 downto 0) & '0'; --Shift through SPI_DATA
                    shift_counter <= shift_counter + 1; --Keep track of what bit it is on
                elsif(clk_divided = '1') then --on SCLK high reset the falling flag
                    falling <= '0';
                end if;
            end if;
        end if;
    end process;

end Behavioral;
