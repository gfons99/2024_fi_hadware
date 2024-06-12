-- ****************************************
-- tittle: Decodificador de 16 bits
-- author: F.R., G.M.
-- date: 2024-04
-- description: Recibe un número entero y lo separa en dígitos, máx 65,535
-- ****************************************
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity deco_1int2dig_a_2int1dig is
    port(
        clk: in std_logic;
        num_2dig: in integer range 0 to 99;
        n0,n1: out integer range 0 to 9
    );
end entity;

architecture frgm of deco_1int2dig_a_2int1dig is

-- 16 bits
signal num_int: integer range 0 to 99;

begin
    process(clk)
    begin
        if rising_edge(clk) then
            num_int <= num_2dig;
        end if;
    end process;
    
    n0 <= num_int mod 10;
    n1 <= (num_int / 10) mod 10;
end architecture;