-- ****************************************
-- tittle:	MAIN MUX ADS1115
-- author:	F.R., G.M.
-- date:	2024-04
-- description: Se controla mediante I2C el MUX-ADC de 16 bits con 4 canales analógicos
-- ****************************************

library ieee;
use ieee.std_logic_1164.all;

entity main_i2c_ads1115 is
	port(
        -- entradas:
        clk_50: in std_logic;
		sw_sel_mux: in std_logic;
        sw_ena: in std_logic;
        sw_rst: in std_logic;
        sw2_sel_ch: in std_logic_vector(1 downto 0);
        sw_busy: in std_logic;

        -- salidas:
        gpio_scl: out std_logic;
        gpio_sda: inout std_logic;
        gpio_uart_tx: inout std_logic;

        led_slave_error: out std_logic;

        led_7s_hex0: out std_logic_vector(7 downto 0);
        led_7s_hex1: out std_logic_vector(7 downto 0);
        led_7s_hex2: out std_logic_vector(7 downto 0);
        led_7s_hex3: out std_logic_vector(7 downto 0);
        led_7s_hex4: out std_logic_vector(7 downto 0);
        led_7s_hex5: out std_logic_vector(7 downto 0);
        
        -- led_7s_edo_i2c: out std_logic_vector(7 downto 0);       -- HEX0
        -- led_7s_edo_ads1115: out std_logic_vector(7 downto 0);   -- HEX1

        -- led_7s_pulso_i2c: out std_logic_vector(7 downto 0);     -- HEX2
        -- led_7s_pulso_ads1115: out std_logic_vector(7 downto 0); -- HEX3

        -- led_7s_cont_bits_i2c: out std_logic_vector(7 downto 0);      -- HEX4
        -- led_7s_cont_bits_ads1115: out std_logic_vector(7 downto 0);  -- HEX5

        led8_debug_mem_bits: out std_logic_vector(7 downto 0)
	);
end entity;

architecture frgm of main_i2c_ads1115 is

    component divf
        generic(
            frec: integer := 24999
        ); -- frec = (50 mhz/2*fdeseada) - 1
        port(
            clk_mst: in std_logic; -- reloj principal
            clk: buffer std_logic
        );
    end component;

    component cont_i2c_ads1115
        port (
            clk: in std_logic;
            ena: in std_logic;
            rst: in std_logic;
            sel_ch: in std_logic_vector(1 downto 0);
    
            o_scl: out std_logic := '1';
            io_sda: inout std_logic := '1';
            
            -- debug_cont_pulso: out integer range 0 to 7;
            -- debug_cont_bits: out integer range 0 to 99;
            -- debug_cont_pos: out integer range 0 to 15;
            -- debug_cont_pos_8b: out integer range 0 to 7;
            -- debug_show_frame: out integer range 0 to 9;
    
            debug_o_mem_1frame_8bits: out std_logic_vector(7 downto 0);
            o_mem_adc_16: out std_logic_vector(15 downto 0)
            
        );
    end component;

    component mux_2x1
        port(
            select_line: in std_logic;
    
            clk_debug: in std_logic;
            clk_release: in std_logic;
            
            clk_mux: out std_logic
        );
    end component;

    component mux_debug_release
        port(
            select_line: in std_logic;
            -- entradas
            i_int0_0: in integer range 0 to 15;
            i_int0_1: in integer range 0 to 15;
            i_int0_2: in integer range 0 to 15;
            i_int0_3: in integer range 0 to 15;
            i_int0_4: in integer range 0 to 15;
            i_int0_5: in integer range 0 to 15;
            
            i_int1_0: in integer range 0 to 15;
            i_int1_1: in integer range 0 to 15;
            i_int1_2: in integer range 0 to 15;
            i_int1_3: in integer range 0 to 15;
            i_int1_4: in integer range 0 to 15;
            i_int1_5: in integer range 0 to 15;
            
            -- salidas
            o_int_0: out integer range 0 to 15;
            o_int_1: out integer range 0 to 15;
            o_int_2: out integer range 0 to 15;
            o_int_3: out integer range 0 to 15;
            o_int_4: out integer range 0 to 15;
            o_int_5: out integer range 0 to 15
        );
    end component;

    component deco_1int2dig_a_2int1dig
        port(
            clk: in std_logic;
            num_2dig: in integer range 0 to 99;
            n0,n1: out integer range 0 to 9
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

    component uart_tx
        port(
            clk: in std_logic; -- 50 MHz
            busy: in std_logic; -- inicia comunicacion -- SWITCH
            dmx,mx,cx,dx,ux: in integer range 0 to 9;
    
            tx_out: out std_logic -- datos a transmitir
        );
    end component;

signal s_clk_divf: std_logic;
signal s_clk_mux: std_logic;

signal s_debug_cont_pulso: integer range 0 to 7;
signal s_debug_cont_bits: integer range 0 to 99;
signal s_debug_cont_pos: integer range 0 to 15;
signal s_debug_cont_pos_8b: integer range 0 to 7;
signal s_debug_show_frame: integer range 0 to 15;
signal s_mem_adc_16: std_logic_vector(15 downto 0);

signal s_int_debug_7s_hex0: integer range 0 to 15;
signal s_int_debug_7s_hex1: integer range 0 to 15;
signal s_int_debug_7s_hex2: integer range 0 to 15;
signal s_int_debug_7s_hex3: integer range 0 to 15;
signal s_int_debug_7s_hex4: integer range 0 to 15;
signal s_int_debug_7s_hex5: integer range 0 to 15;

signal s_int_release_7s_hex0: integer range 0 to 15;
signal s_int_release_7s_hex1: integer range 0 to 15;
signal s_int_release_7s_hex2: integer range 0 to 15;
signal s_int_release_7s_hex3: integer range 0 to 15;
signal s_int_release_7s_hex4: integer range 0 to 15;
signal s_int_release_7s_hex5: integer range 0 to 15;

signal s_led_7s_hex0: integer range 0 to 15;
signal s_led_7s_hex1: integer range 0 to 15;
signal s_led_7s_hex2: integer range 0 to 15;
signal s_led_7s_hex3: integer range 0 to 15;
signal s_led_7s_hex4: integer range 0 to 15;
signal s_led_7s_hex5: integer range 0 to 15;

begin
    divisor_simple: divf
    generic map(
        -- 24999    >> 1 khz
        -- 249999   >> 100 hz
        -- 2499999  >> 10 hz
        -- 24999999 >> 1 hz
        frec=> 2499999
    )
    port map(
        clk_50,
        s_clk_divf
    );
    mux_clk: mux_2x1 port map(
        sw_sel_mux,
        s_clk_divf,
        clk_50,
        s_clk_mux
    );
    logica_i2c_ads1115: cont_i2c_ads1115 port map(
        s_clk_mux,
        sw_ena,
        sw_rst,
        sw2_sel_ch,
        gpio_scl,
        gpio_sda,
        -- s_debug_cont_pulso,
        -- s_debug_cont_bits,
        -- s_debug_cont_pos,
        -- s_debug_cont_pos_8b,
        -- s_debug_show_frame,
        led8_debug_mem_bits,
        s_mem_adc_16
        
    );
    mux_dbg_rls: mux_debug_release port map(
        -- entradas
        sw_sel_mux,

        s_debug_cont_pulso,     -- pulso
        s_int_debug_7s_hex1,    -- bits dig0
        s_int_debug_7s_hex2,    -- bits dig1
        s_debug_cont_pos,       -- pos
        s_debug_cont_pos_8b,    -- pos 8b
        s_debug_show_frame,     -- frame

        s_int_release_7s_hex0,
        s_int_release_7s_hex1,
        s_int_release_7s_hex2,
        s_int_release_7s_hex3,
        s_int_release_7s_hex4,
        s_int_release_7s_hex5,

        -- salidas
        s_led_7s_hex0,
        s_led_7s_hex1,
        s_led_7s_hex2,
        s_led_7s_hex3,
        s_led_7s_hex4,
        s_led_7s_hex5
    );
    deco_bits: deco_1int2dig_a_2int1dig port map(
        clk_50,
        s_debug_cont_bits,
        s_int_debug_7s_hex1,
        s_int_debug_7s_hex2
    );
    deco_adc: deco_16b_a_5int port map(
        clk_50,
        s_mem_adc_16,
        s_int_release_7s_hex4,
        s_int_release_7s_hex3,
        s_int_release_7s_hex2,
        s_int_release_7s_hex1,
        s_int_release_7s_hex0
    );
	deco_hex0: deco_bin_a_7seg port map(
        s_led_7s_hex0,
        led_7s_hex0
	);
	deco_hex1: deco_bin_a_7seg port map(
        s_led_7s_hex1,
        led_7s_hex1
	);
	deco_hex2: deco_bin_a_7seg port map(
        s_led_7s_hex2,
        led_7s_hex2
	);
	deco_hex3: deco_bin_a_7seg port map(
        s_led_7s_hex3,
        led_7s_hex3
	);
	deco_hex4: deco_bin_a_7seg port map(
        s_led_7s_hex4,
        led_7s_hex4
	);
	deco_hex5: deco_bin_a_7seg port map(
        s_led_7s_hex5,
        led_7s_hex5
	);
	ads1115_uart_tx: uart_tx port map(
        clk_50,
        sw_busy,
        s_int_release_7s_hex4,
        s_int_release_7s_hex3,
        s_int_release_7s_hex2,
        s_int_release_7s_hex1,
        s_int_release_7s_hex0,
        gpio_uart_tx
	);

end architecture;
