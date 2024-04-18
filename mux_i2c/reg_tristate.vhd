-- ****************************************
-- tittle: Registro con lógica de tercer estado (Tri-State)
-- author: F.R., G.M.
-- date: 2024-04-10
-- description:
-- -- Estados lógicos: '0', '1', 'Z' (alta impedancia)
-- ****************************************

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity reg_tristate is
	port(
		enable: in std_logic;
		entrada: in std_logic;
		salida: out std_logic
	);
end entity;

architecture frgm of reg_tristate is
begin
	process(enable)
	begin
		if (enable='1') then
			salida <= entrada;
		else
			salida <= 'Z';
		end if;
	end process;
end architecture;