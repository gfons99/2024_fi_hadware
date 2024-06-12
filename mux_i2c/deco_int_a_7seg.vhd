-- ****************************************
-- tittle:	Decodificador de integer a 7 segmentos
-- author:	F.R., G.M.
-- date:		2024-04
-- description: *
-- ****************************************

library ieee;
use ieee.std_logic_1164.all;

entity deco_bin_a_7seg is
port(
	num: in integer range 0 to 15;
	seg: out std_logic_vector(7 downto 0)
	);
end entity;

architecture frgm of deco_bin_a_7seg is
begin
	with num select
				  --abcdefg,dp
		seg <= 	
			"00000011" when 0,
			"10011111" when 1,
			"00100101" when 2,
			"00001101" when 3,
			"10011001" when 4,
			"01001001" when 5,
			"01000001" when 6,
			"00011111" when 7,
			"00000001" when 8,
			"00001001" when 9,
			"00010001" when 10, -- A
			"11000001" when 11, -- B
			"01100011" when 12, -- C
			"10000101" when 13, -- D
			"01100001" when 14, -- E
			"01110001" when 15; -- F
end architecture;