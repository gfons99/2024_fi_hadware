-- ****************************************
-- tittle: Divisor de frecuencia con atraso
-- author:	F.R., G.M.
-- based on the code created by: M.I. B.E.A.S.
-- date: 2024-04
-- description:
-- ****************************************

library ieee;
use ieee.std_logic_1164.all;

generic(k_scl: integer := 7); -- k = (50 mhz/2*fdeseada) - 1
generic(k_dlc: integer := 3); -- k = (50 mhz/2*fdeseada) - 1
generic(atraso: integer := 1); -- atraso = (periodo/4) = ((k+1)/4)

entity divf_scl_dcl is
    port (
        -- entradas:
        clk_mst: in std_logic;
        -- salidas:
        scl: out std_logic;
        dcl: out std_logic;
    );
end entity;

architecture frgm of divf_scl_dcl is 

signal cont_scl: integer range 0 to k_scl := atraso;
signal cont_dcl2: integer range 0 to k_dlc := 0;

begin
    
    process(clk)
    begin

        -- reloj scl atrasado 1/4 de periodo respecto a dcl
        if rising_edge(clk) then
            if cont_scl = 0 then
                scl <= not scl;
                cont_scl <= k_scl;
            else
                cont_scl <= cont_scl - 1;
            end if;
        end if;

        -- reloj dcl sin retraso
        if rising_edge(clk) then
            if cont_dcl2 = 0 then
                dcl <= not dcl;
                cont_dcl2 <= k_dcl;
            else
                cont_dcl2 <= cont_dcl2 - 1;
            end if;
        end if;

    end process;
end architecture;
