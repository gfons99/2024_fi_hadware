-- ****************************************
-- tittle:    Multiplexor 4x1
-- author:    F.R., G.M.
-- date:        2024-03-08
-- description: Permite seleccionar las entradas Q0...QN
-- ****************************************
library ieee;
use ieee.std_logic_1164.all;

entity mux_2x1 is
    port(
        select_line: in std_logic;

        clk_debug: in std_logic;
        clk_release: in std_logic;
        
        clk_mux: out std_logic
    );
end entity;

architecture frgm of mux_2x1 is
begin
    with select_line select
        clk_mux <=
            clk_debug when '0',
            clk_release when '1';
end architecture;