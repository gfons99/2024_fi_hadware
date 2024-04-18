-- ****************************************
-- tittle:
-- author:	F.R., G.M.
-- date: 2024-04
-- description:
-- ****************************************

library ieee;
use ieee.std_logic_1164.all;

generic(k: integer := 7); -- k = (50 mhz/2*fdeseada) - 1
generic(atraso: integer := 2); -- atraso = (periodo/4) = ((k+1)/4)

entity scl_sda is
    port (
        -- entradas:
        e_scl: in std_logic;
        e_sda: in std_logic;

        i_scl: in std_logic;
        i_sda: in std_logic;

        -- salidas:
        o_scl: out std_logic := '1';
        o_sda: out std_logic := '1';
    );
end entity;

architecture frgm of scl_sda is 

signal cont_scl: integer range 0 to k := atraso;
signal cont_dcl: integer range 0 to k := 0;

begin
    
    process(clk_dcl)
    begin
        if rising_edge(clk_dcl) then
            if e_sda = '0' then
                o_sda <= i_sda;
            else
                o_sda <= '1';
            end if;
        end if;
    end process;
end architecture;
