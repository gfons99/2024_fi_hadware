-- ****************************************
-- tittle: Decodificador de 16 bits
-- author: F.R., G.M.
-- date: 2024-04
-- description: Recibe un número entero y lo separa en dígitos
-- ****************************************
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity deco_16b_5num is
    port(
        clk: in std_logic;
        num_bin: in std_logic_vector(15 downto 0);
        n4,n3,n2,n1,n0: out integer range 0 to 9
    );
end entity;

architecture frgm of deco_16b_5num is

-- 16 bits
signal num_int: integer range 0 to 65535;

begin
    process(clk)
    begin
        if rising_edge(clk) then
            num_int <= to_integer(unsigned(num_bin));
        end if;
    end process;
    
    n0 <= num_int mod 10;
    n1 <= (num_int / 10) mod 10;
    n2 <= (num_int / 100) mod 10;
    n3 <= (num_int / 1000) mod 10;
    n4 <= (num_int / 10000) mod 10;
end architecture;