-- ****************************************
-- tittle:	MAIN MUX ADS1115
-- author:	F.R., G.M.
-- date:	2024-04
-- description: Se controla mediante I2C el MUX-ADC de 16 bits con 4 canales analógicos
-- ****************************************

library ieee;
use ieee.std_logic_1164.all;

entity mux_i2c_main is
	port(
        -- entradas:
        clk_50: in std_logic;
        sw_rst: in std_logic;
        sw_adc_ch: in std_logic_vector(1 downto 0);

        -- salidas:
        x_scl: inout std_logic;
        x_sda: inout std_logic;
        led_slave_error: out std_logic;
        
        led_7s_edo_i2c: out std_logic_vector(7 downto 0);       -- HEX0
        led_7s_edo_ads1115: out std_logic_vector(7 downto 0);   -- HEX1

        led_7s_pulso_i2c: out std_logic_vector(7 downto 0);     -- HEX2
        led_7s_pulso_ads1115: out std_logic_vector(7 downto 0);     -- HEX3

        -- led_7s_dig4: out std_logic_vector(7 downto 0);
        -- led_7s_dig3: out std_logic_vector(7 downto 0);
        -- led_7s_dig2: out std_logic_vector(7 downto 0);
        -- led_7s_dig1: out std_logic_vector(7 downto 0);
        -- led_7s_dig0: out std_logic_vector(7 downto 0)

        led_bits_8: out std_logic_vector(7 downto 0)
	);
end entity;

architecture frgm of mux_i2c_main is

    component divf
        generic(
            frec: integer := 24999
        ); -- frec = (50 mhz/2*fdeseada) - 1
        port(
            clk_mst: in std_logic; -- reloj principal
            clk: buffer std_logic
        );
    end component;

    component i2c_general_fsm
        port (
            -- entradas:
            clk_50: in std_logic;
            rst: in std_logic;
            ena: in std_logic;
    
            io_scl: inout std_logic := '1';
            io_sda: inout std_logic := '1';
            
            i_rx: in std_logic;
            o_tx: out std_logic;
    
            o_error: out std_logic;
            o_show_edo: out integer range 0 to 9;
            o_show_pulso: out integer range 0 to 9;
            debug_o_mem_bits_rx: out std_logic_vector(7 downto 0)
        );
    end component;

    component i2c_ads1115_fsm
        port (
            -- entradas:
            clk: in std_logic;
            rst: in std_logic;
            ena: out std_logic;
    
            i_rx: in std_logic;
            o_tx: out std_logic;
            
            -- entradas:
            sw_adc_ch: in std_logic_vector(1 downto 0);
    
            -- salidas:
            o_show_edo: out integer range 0 to 9;
            o_show_pulso: out integer range 0 to 9;
            adc_16b: out std_logic_vector(15 downto 0)
        );
    end component;

    component deco_16b_5num
        port(
            clk: in std_logic;
            num_bin: in std_logic_vector(15 downto 0);
            n4,n3,n2,n1,n0: out integer range 0 to 9
        );
    end component;

    component deco_bin_a_7seg
        port(
            num: in integer range 0 to 9;
            seg: out std_logic_vector(7 downto 0)
        );
    end component;

signal s_clk_divf: std_logic;
signal s_clk_0_7: std_logic;
signal s_ena: std_logic;
signal s_rx: std_logic;
signal s_tx: std_logic;

signal s_o_show_edo_i2c: integer range 0 to 9;
signal s_o_show_edo_ads1115: integer range 0 to 9;
signal s_o_show_pulso_i2c: integer range 0 to 9;
signal s_o_show_pulso_ads1115: integer range 0 to 9;
signal s_adc_16b: std_logic_vector(15 downto 0);
signal s_dig4,s_dig3,s_dig2,s_dig1,s_dig0: integer range 0 to 9; 

begin
    divisor_simple: divf
    generic map(
        -- 24999    >> 1 khz
        -- 249999   >> 100 hz
        -- 2499999  >> 10 hz
        -- 24999999 >> 1 hz
        frec=> 24999999
    )
    port map(
        clk_50,
        s_clk_divf
    );
    divisor_0_7: divf
    generic map(
        frec=> 7
    )
    port map(
        s_clk_divf,
        s_clk_0_7
    );
    i2c: i2c_general_fsm port map(
        s_clk_divf,
        sw_rst,
        s_ena,

        x_scl,
        x_sda,

        s_rx,
        s_tx,

        led_slave_error,
        s_o_show_edo_i2c,
        s_o_show_pulso_i2c,
        led_bits_8
    );
    ads1115: i2c_ads1115_fsm port map(
        s_clk_0_7,
        sw_rst,
        s_ena,
        s_tx,
        s_rx,
        sw_adc_ch,
        s_o_show_edo_ads1115,
        s_o_show_pulso_ads1115,
        s_adc_16b
    );
	deco_edo_i2c: deco_bin_a_7seg port map(
        s_o_show_edo_i2c,
        led_7s_edo_i2c
	);
	deco_edo_ads1115: deco_bin_a_7seg port map(
        s_o_show_edo_ads1115,
        led_7s_edo_ads1115
	);
    deco_pulso_i2c: deco_bin_a_7seg port map(
        s_o_show_pulso_i2c,
        led_7s_pulso_i2c
	);
    deco_pulso_ads1115: deco_bin_a_7seg port map(
        s_o_show_pulso_ads1115,
        led_7s_pulso_ads1115
	);
end architecture;
