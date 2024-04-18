-- ****************************************
-- tittle: Divisor de frecuencia con atraso
-- author:	F.R., G.M.
-- based on the code created by: M.I. B.E.A.S.
-- date: 2024-04
-- description:
-- ****************************************

library ieee;
use ieee.std_logic_1164.all;

entity divf_scl_dcl is
	generic(
        k_scl: integer := 7; -- k = (50 mhz/2*fdeseada) - 1
        k_dcl: integer := 3; -- k = (50 mhz/2*fdeseada) - 1
        atraso: integer := 1 -- atraso = (periodo/4) = ((k+1)/4)

    ); 

    port (
        -- entradas:
        clk: in std_logic;
        -- salidas:
        scl: buffer std_logic := '0';
        dcl: buffer std_logic := '0';
        dlc_not: buffer std_logic := '1'
    );
end entity;

architecture frgm of divf_scl_dcl is 

signal cont_scl: integer range 0 to k_scl := atraso;
signal cont_dcl: integer range 0 to k_dcl := 0;

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
            if cont_dcl = 0 then
                dcl <= not dcl;
                dlc_not <= not dlc_not;
                cont_dcl <= k_dcl;
            else
                cont_dcl <= cont_dcl - 1;
            end if;
        end if;

    end process;
end architecture;
