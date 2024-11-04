-- ****************************************
-- tittle: DIVISOR DE FRECUENCIA POSITVO
-- author: F.R., G.M.
-- date: 2024-11
-- ****************************************

library ieee;
use ieee.std_logic_1164.all;

entity div_freq_pos is
	-- k = (50 mhz/2*fdeseada) - 1

	-- 24999    >> 1 khz
	-- 249999   >> 100 hz
	-- 2499999  >> 10 hz
	-- 24999999 >> 1 hz
	generic(
		k: integer := 24999
	); 
	port(
		clk_mst: in std_logic;
		clk_div: buffer std_logic
	);
end entity;

architecture frgm of div_freq_pos is
signal cont: integer range 0 to k;
begin

	process(clk_mst)
	begin
		if rising_edge (clk_mst) then
			if cont = k then
				clk_div <= not clk_div;
				cont <= 0;
			else
				cont <= cont + 1;
			end if;
		end if;
	end process;

end architecture;