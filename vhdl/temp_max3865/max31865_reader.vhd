library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity max31865_reader is
    port (
        clk        : in std_logic;       -- System clock
        start      : in std_logic;       -- Start signal for initiating SPI communication

        sclk        : buffer std_logic;   -- SPI clock (to MAX31865)
        cs         : out std_logic;      -- Chip Select (active low)
        mosi       : out std_logic;      -- Master Out Slave In
        miso       : in std_logic;       -- Master In Slave Out (data from MAX31865)
        
        data_out   : out std_logic_vector(15 downto 0); -- Output register for RTD data
        done       : out std_logic       -- Done signal to indicate data is ready
    );
end max31865_reader;

architecture behavioral of max31865_reader is

    -- State machine states
    type state_type is (IDLE, WRITE_CONFIG_REG, READ_RTD_MSB, READ_RTD_LSB, COMPLETE);
    signal state : state_type := IDLE;

    -- Internal signals
    signal cont_clk   : integer := 0;                                        -- Clock divider for SPI clock
    signal bit_count : integer range 0 to 15 := 0;                                        -- Bit counter for SPI data
    signal mosi_data : std_logic_vector(7 downto 0) := "00000000";          -- Data to send on MOSI
    signal miso_data  : std_logic_vector(15 downto 0) := (others => '0');    -- Received data register

    -- SPI clock divider
    constant CONT_FREQ_MAX : integer := 4;  -- Adjust for your system clock speed

begin

    -- SPI Clock generation
    process (clk)
    begin
        if rising_edge(clk) then
            if cont_clk = CONT_FREQ_MAX then
                sclk <= not sclk;
                cont_clk <= 0;
            else
                cont_clk <= cont_clk + 1;
            end if;
        end if;
    end process;

    -- SPI State Machine
    process (clk)
    begin
        if rising_edge(clk) then
            case state is

                when IDLE =>
                    -- sclk <= '0';

                    cs <= '1';   -- inactive
                    mosi <= 'Z';

                    done <= '0';
                    
                    bit_count <= 7;

                    if start = '1' then
                        mosi_data <= "11000010"; -- Send read command (0x01) for RTD MSB register
                        cs <= '0';
                        state <= WRITE_CONFIG_REG;
                    end if;

                when WRITE_CONFIG_REG =>
                    mosi <= mosi_data(bit_count);
                    if bit_count > 0 then
                        bit_count <= bit_count - 1;
                    else
                        state <= READ_RTD_MSB;
                        bit_count <= 15;
                    end if;

                when READ_RTD_MSB =>
                    if sclk = '0' then
                        miso_data(bit_count) <= miso; -- Shift in MSB data
                        if bit_count > 8 then
                            bit_count <= bit_count - 1;
                        else
                            state <= READ_RTD_LSB;
                            bit_count <= 7;
                        end if;
                    end if;

                when READ_RTD_LSB =>
                    if sclk = '0' then
                        miso_data(bit_count) <= miso; -- Shift in MSB data
                        if bit_count > 0 then
                            bit_count <= bit_count - 1;
                        else
                            state <= COMPLETE;
                            bit_count <= 7;
                        end if;
                    end if;

                when COMPLETE =>
                    cs <= '1';                 -- Deactivate CS
                    -- data_out <= miso_data;     -- Output the  RTD data
                    data_out <= "1111111111111111";
                    done <= '1';               -- Set done signal
                    state <= IDLE;             -- Go back to idle

                when others =>
                    state <= IDLE;
                    
            end case;
        end if;
    end process;

end behavioral;
