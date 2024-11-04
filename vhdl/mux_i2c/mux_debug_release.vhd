-- ****************************************
-- tittle:	Multiplexor 5x5
-- author:	F.R., G.M.
-- ****************************************
library ieee;
use ieee.std_logic_1164.all;

entity mux_debug_release is
    port(
        select_line: in std_logic;
        -- entradas
        i_int0_0: in integer range 0 to 15;
        i_int0_1: in integer range 0 to 15;
        i_int0_2: in integer range 0 to 15;
        i_int0_3: in integer range 0 to 15;
        i_int0_4: in integer range 0 to 15;
        i_int0_5: in integer range 0 to 15;
        
        i_int1_0: in integer range 0 to 15;
        i_int1_1: in integer range 0 to 15;
        i_int1_2: in integer range 0 to 15;
        i_int1_3: in integer range 0 to 15;
        i_int1_4: in integer range 0 to 15;
        i_int1_5: in integer range 0 to 15;
        
        -- salidas
        o_int_0: out integer range 0 to 15;
        o_int_1: out integer range 0 to 15;
        o_int_2: out integer range 0 to 15;
        o_int_3: out integer range 0 to 15;
        o_int_4: out integer range 0 to 15;
        o_int_5: out integer range 0 to 15
	);
end entity;

architecture frgm of mux_debug_release is
begin
    with select_line select
        o_int_0 <= i_int0_0 when '0', i_int1_0 when '1';
    with select_line select
        o_int_1 <= i_int0_1 when '0', i_int1_1 when '1';
    with select_line select
        o_int_2 <= i_int0_2 when '0', i_int1_2 when '1';
    with select_line select
        o_int_3 <= i_int0_3 when '0', i_int1_3 when '1';
    with select_line select
        o_int_4 <= i_int0_4 when '0', i_int1_4 when '1';
    with select_line select
        o_int_5 <= i_int0_5 when '0', i_int1_5 when '1';
end architecture;