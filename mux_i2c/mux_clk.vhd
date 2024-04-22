-- ****************************************
-- tittle:	Multiplexor
-- author:	F.R., G.M.
-- date:		2024-04
-- description: Permite seleccionar las entradas clk0...clkN
-- ****************************************
library ieee;
use ieee.std_logic_1164.all;

entity mux_clk is
	port(
	clk0, clk1, clk2, clk3: in std_logic;
	sel: in std_logic_vector(1 downto 0);
	
	clk: out std_logic
	);
end entity;

architecture frgm of mux_clk is
begin
	with sel select
		clk <=
			clk0 when "00",
			clk1 when "01",
			clk2 when "10",
			clk3 when "11";
end architecture;