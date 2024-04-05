-- ****************************************
-- tittle:	MAIN
-- author:	F.R., G.M.
-- date:	2024-04-05
-- description: 
-- ****************************************

library ieee;
use ieee.std_logic_1164.all;

entity main_adc is
	port(
		clk_50: in std_logic;
		a_sel: std_logic_vector(1 downto 0);
		-- d0,d1,d2,d3: out std_logic_vector(7 downto 0)
	);
end entity;

architecture frgm of main_adc is
	
	-- ********************
	component adc_frgm
		port (
			clock : in  std_logic                     := '0'; --      clk.clk
			ch0   : out std_logic_vector(11 downto 0);        -- readings.ch0
			reset : in  std_logic                     := '0'  --    reset.reset
		);
	end component;
	
	-- ********************
	component divf
		generic(frec: integer := 24999); -- frec = (50 mhz/2*fdeseada) - 1
		port(
			clk_mst: in std_logic; -- reloj principal
			clk: buffer std_logic
		);
	end component;

	-- ********************


signal s_clk: std_logic;
signal s_mux: integer range 0 to 400;
signal s_ch0: std_logic_vector(11 downto 0); 
signal s_mx,s_cx,s_dx,s_ux: integer range 0 to 9;

begin

	-- 2499    >> 10 khz
	-- 24999    >> 1 khz
	-- 249999   >> 100 hz
	-- 2499999  >> 10 hz
	-- 24999999 >> 1 hz
	b1: divf generic map(frec=> 24999999) port map(clk_50, s_clk);
	b2: adc_frgm port map(clk_adc, s_ch0,reset);
	b3: deco_mdcu port map(s_clk,s_ch0,s_mx,s_cx,s_dx,s_ux);
	
	b4: deco7s_09 port map(s_ux,d0);
	b5: deco7s_09 port map(s_dx,d1);
	b6: deco7s_09 port map(s_cx,d2);
	b7: deco7s_09 port map(s_mx,d3);

end frgm;
