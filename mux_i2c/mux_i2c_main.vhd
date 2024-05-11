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
        x_scl: out std_logic;
        x_sda: buffer std_logic;
        led_slave_error: out std_logic;
        
        led_7s_frame: out std_logic_vector(7 downto 0);
        led_7s_dig4: out std_logic_vector(7 downto 0);
        led_7s_dig3: out std_logic_vector(7 downto 0);
        led_7s_dig2: out std_logic_vector(7 downto 0);
        led_7s_dig1: out std_logic_vector(7 downto 0);
        led_7s_dig0: out std_logic_vector(7 downto 0)
	);
end entity;

architecture frgm of mux_i2c_main is

    component divf_scl_dcl
        generic(
            k_scl: integer := 7; -- k = (50 mhz/2*fdeseada) - 1
            k_dcl: integer := 3; -- k = (50 mhz/2*fdeseada) - 1
            atraso: integer := 1 -- atraso = (periodo/4) = ((k+1)/4)
        ); 
        port (
            clk: in std_logic;
            scl: buffer std_logic := '0';
            dcl: buffer std_logic := '0';
            dlc_not: buffer std_logic := '1'
        );
    end component;

    component i2c_general_fsm
        port (
            -- entradas:
            dcl: in std_logic;
            rst, ena: in std_logic;
    
            i_write: in std_logic;
            i_sda: in std_logic;
            -- salidas:
            sel_scl: out std_logic_vector(1 downto 0) := "01"; -- 00: scl    -- 01: '1'
            sel_sda: out std_logic_vector(1 downto 0) := "01"; -- 00: dcl    -- 01: '1' o -- 10: datos -- 11: not dcl
    
            o_read:out std_logic;
            o_sda: out std_logic := '1';
    
            o_slave_error: out std_logic
        );
    end component;

    component i2c_ads1115_fsm
        port (
            -- entradas:
            dcl: in std_logic;
            sw_adc_ch: in std_logic_vector(1 downto 0);
            rst: in std_logic;
            i_read: in std_logic;
    
            -- salidas:
            o_ena: out std_logic;
            o_write: out std_logic;
				o_show_edo_frame: out integer range 1 to 5;
            adc_16b: out std_logic_vector(15 downto 0)
        );
    end component;

    component mux_clk
        port(
        clk0, clk1, clk2, clk3: in std_logic;
        sel: in std_logic_vector(1 downto 0);
        
        clk: out std_logic
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

signal s_scl: std_logic;
signal s_dcl,s_not_dcl: std_logic;
signal s_ena: std_logic;
signal s_write: std_logic;
signal s_sel_scl: std_logic_vector(1 downto 0) := "01";
signal s_sel_sda: std_logic_vector(1 downto 0) := "01";
signal s_read: std_logic;
signal s_o_sda: std_logic := '1';
-- signal s_o_slave_error: std_logic;
signal s_o_show_edo_frame: integer range 1 to 5;
signal s_adc_16b: std_logic_vector(15 downto 0);
signal s_dig4,s_dig3,s_dig2,s_dig1,s_dig0: integer range 0 to 9; 

begin
    
    relojes: divf_scl_dcl 
        generic map(
            k_scl => 7,
            k_dcl => 3,
            atraso => 1
            )
        port map(
            clk_50,
            s_scl,
            s_dcl,
            s_not_dcl
        );

    i2c_puro: i2c_general_fsm port map(
        s_dcl,
        sw_rst,
        s_ena,
        s_write,
        x_sda,
        s_sel_scl,
        s_sel_sda,
        s_read,
        s_o_sda,
        led_slave_error
    );
    ads1115: i2c_ads1115_fsm port map(
        s_dcl,
        sw_adc_ch,
        sw_rst,
        s_read,
        s_ena,
        s_write,
		s_o_show_edo_frame,
        s_adc_16b
    );
    mux_scl: mux_clk port map(
        s_scl,
        '1',
        '1', -- NO USAR
        '1', -- NO USAR
        sw_adc_ch,
        x_scl
    );
    mux_sda: mux_clk port map(
        s_dcl,
        '1',
        s_o_sda,
        s_not_dcl,
        sw_adc_ch,
        x_sda
    );
	deco_edo_frame: deco_bin_a_7seg port map(
        s_o_show_edo_frame,
        led_7s_frame
	);
	 
    deco_adc_16b: deco_16b_5num port map(
        s_dcl,
        s_adc_16b,
        s_dig4,s_dig3,s_dig2,s_dig1,s_dig0
    );
    dig4_7seg: deco_bin_a_7seg port map(
        s_dig4,
        led_7s_dig4
    );
    dig3_7seg: deco_bin_a_7seg port map(
        s_dig3,
        led_7s_dig3
    );
    dig2_7seg: deco_bin_a_7seg port map(
        s_dig2,
        led_7s_dig2
    );
    dig1_7seg: deco_bin_a_7seg port map(
        s_dig1,
        led_7s_dig1
    );
    dig0_7seg: deco_bin_a_7seg port map(
        s_dig0,
        led_7s_dig0
    );
    

	-- 2499    >> 10 khz
	-- 24999    >> 1 khz
	-- 249999   >> 100 hz
	-- 2499999  >> 10 hz
	-- 24999999 >> 1 hz
	-- b1: divf generic map(frec=> 24999999) port map(clk_50, s_clk);
	-- b2: adc_frgm port map(clk_adc, s_ch0,reset);
	-- b3: deco_mdcu port map(s_clk,s_ch0,s_mx,s_cx,s_dx,s_ux);
	
	-- b4: deco7s_09 port map(s_ux,d0);
	-- b5: deco7s_09 port map(s_dx,d1);
	-- b6: deco7s_09 port map(s_cx,d2);
	-- b7: deco7s_09 port map(s_mx,d3);

end architecture;
