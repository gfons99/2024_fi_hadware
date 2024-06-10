-- ****************************************
-- DIVISOR DE FRECUENCIA
-- author: M.I. B.E.A.S.
-- date: 2022-02-07
-- ****************************************

library ieee;
use ieee.std_logic_1164.all;

entity divf is
	-- 24999    >> 1 khz
	-- 249999   >> 100 hz
	-- 2499999  >> 10 hz
	-- 24999999 >> 1 hz
	generic(
		frec: integer := 24999
	); -- frec = (50 mhz/2*fdeseada) - 1
	port(
		clk_mst: in std_logic; -- reloj principal
		clk: buffer std_logic
	);
end entity;

architecture beas of divf is
signal aux: integer range 0 to frec;
begin

	process(clk_mst)
	begin
		if rising_edge (clk_mst) then
			if aux = 0 then
				clk <= not clk;
				aux <= frec;
			else
				aux <= aux - 1;
			end if;
		end if;
	end process;

end beas;