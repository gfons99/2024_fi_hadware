-- ****************************************
-- tittle:    MAIN MUX ADS1115
-- author:    F.R., G.M.
-- date:    2024-04
-- description: Se controla mediante I2C el MUX-ADC de 16 bits con 4 canales analógicos
-- ****************************************

library ieee;
use ieee.std_logic_1164.all;

entity main is
    port(
        clk_50 : in std_logic;
        sw_start : in std_logic;

        pin_max31865_clk : out std_logic;
        pin_max31865_cs : out std_logic;
        pin_max31865_mosi : out std_logic;
        pin_max31865_miso : in std_logic;

        led_7s_hex0: out std_logic_vector(7 downto 0);
        led_7s_hex1: out std_logic_vector(7 downto 0);
        led_7s_hex2: out std_logic_vector(7 downto 0);
        led_7s_hex3: out std_logic_vector(7 downto 0);
        led_7s_hex4: out std_logic_vector(7 downto 0);
        led_7s_hex5: out std_logic_vector(7 downto 0)
    );
end entity;

architecture frgm of main is

    -- COMPONENTS ********************************
    component divf
        generic(
            frec: integer := 24999
        ); -- frec = (50 mhz/2*fdeseada) - 1
        port(
            clk_mst: in std_logic; -- reloj principal
            clk: buffer std_logic
        );
    end component;

    component max31865_reader
        port (
            clk        : in std_logic;       -- System clock
            start      : in std_logic;       -- Start signal for initiating SPI communication
    
            sclk       : out std_logic;      -- SPI clock (to MAX31865)
            cs         : out std_logic;      -- Chip Select (active low)
            mosi       : out std_logic;      -- Master Out Slave In
            miso       : in std_logic;       -- Master In Slave Out (data from MAX31865)
            
            data_out   : out std_logic_vector(15 downto 0); -- Output register for RTD data
            done       : out std_logic       -- Done signal to indicate data is ready
        );
    end component;

    component deco_16b_a_5int
        port(
            clk: in std_logic;
            num_bin: in std_logic_vector(15 downto 0);
            n4,n3,n2,n1,n0: out integer range 0 to 9
        );
    end component;

    component deco_bin_a_7seg
        port(
            num: in integer range 0 to 15;
            seg: out std_logic_vector(7 downto 0)
        );
    end component;
    -- FIN - COMPONENTES ********************************

-- SEÑALES ********************************
signal s_clk_divf: std_logic;
signal s_clk_mux: std_logic;

signal s_max31865_data : std_logic_vector(15 downto 0);
signal s_max31865_done : std_logic;

signal s_int_to_bin_hex0: integer range 0 to 15;
signal s_int_to_bin_hex1: integer range 0 to 15;
signal s_int_to_bin_hex2: integer range 0 to 15;
signal s_int_to_bin_hex3: integer range 0 to 15;
signal s_int_to_bin_hex4: integer range 0 to 15;
signal s_int_to_bin_hex5: integer range 0 to 15;
-- FIN - SEÑALES ********************************

begin
    max3865: max31865_reader port map(
        clk_50,
        sw_start,
        pin_max31865_clk,
        pin_max31865_cs,
        pin_max31865_mosi,
        pin_max31865_miso,
        s_max31865_data,
        s_max31865_done
    );

    deco_adc_7s: deco_16b_a_5int port map(
        clk_50,
        s_max31865_data,
        s_int_to_bin_hex4,
        s_int_to_bin_hex3,
        s_int_to_bin_hex2,
        s_int_to_bin_hex1,
        s_int_to_bin_hex0
    );

    deco_hex0: deco_bin_a_7seg port map(
        s_int_to_bin_hex0,
        led_7s_hex0
    );
    deco_hex1: deco_bin_a_7seg port map(
        s_int_to_bin_hex1,
        led_7s_hex1
    );
    deco_hex2: deco_bin_a_7seg port map(
        s_int_to_bin_hex2,
        led_7s_hex2
    );
    deco_hex3: deco_bin_a_7seg port map(
        s_int_to_bin_hex3,
        led_7s_hex3
    );
    deco_hex4: deco_bin_a_7seg port map(
        s_int_to_bin_hex4,
        led_7s_hex4
    );
    deco_hex5: deco_bin_a_7seg port map(
        s_int_to_bin_hex5,
        led_7s_hex5
    );



end architecture;
