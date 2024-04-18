-- ****************************************
-- tittle:	Controlador para el ADS1115
-- author:	F.R., G.M.
-- date: 2024-04
-- description: Máquina de estados de Moore
-- ****************************************

library ieee;
use ieee.std_logic_1164.all;

entity i2c_fsm is
    port (
        -- entradas:
        dcl, scl: in std_logic;
        rst, ena: in std_logic;

        datos: in std_logic;        
        i_sda: in std_logic;
        -- salidas:
        sel_scl: out std_logic_vector(1 downto 0) := "01"; -- 0: scl    -- 1: '1'
        sel_sda: out std_logic_vector(1 downto 0) := "01"; -- 0: dcl    -- 1: '1' o datos

        o_sda: out std_logic := '1';
        o_slave_error: out std_logic
    );
end entity;

architecture frgm of i2c_fsm is 
    type estados is(edo0,edo1,edo2,edo3,edo4,edo5,edo6,e_slv_error);
    signal presente: estados := edo0;
    signal bits : integer range 0 to 7 := 0;
    -- (r/_w): '1' read, '0' write
    constant dir_slave_rw: std_logic_vector(7 downto 0) := "10010000"; -- dirección del esclavo & rw

begin
    process(dcl, scl)
    begin
        if rst = '1' then
            presente <= edo0;
        elsif rising_edge(dcl) then
            case presente is
                when edo0 => -- READY 1
                    -- edo. siguiente
                    if ena = '0' then
                        presente <= edo0;
                    else
                        presente <= edo1;
                    end if;
                    -- entradas / salidas
                    sel_scl <= "01";
                    sel_sda <= "01";

                when edo1 => -- START
                    -- edo. siguiente
                    presente <= edo2;
                    -- entradas / salidas
                    sel_scl <= "01";
                    sel_sda <= "00"; -- dcl

                -- ****** FRAME 1: SLAVE RECEIVER ADDRESS ******
                when edo2 => -- slave receiver address (7 bits: orden de envío real="6543210 & rw", orden de envío lógico="0123456  & rw")
                    -- edo. siguiente
                    if bits < 7 then
                        presente <= edo2;
                        bits <= bits + 1;
                    else
                        presente <= edo3;
                        bits <= 0;
                    end if;
                    -- entradas / salidas
                    sel_scl <= "00"; -- scl
                    sel_sda <= "01"; -- datos
                    o_sda <= dir_slave_rw(bits);

                when edo3 => -- ack o _ack
                    -- edo. siguiente
                    presente <= edo4;
                    -- entradas / salidas
                    sel_scl <= "00"; -- scl
                    sel_sda <= "01"; -- datos
                    o_sda <= 'Z';

                -- ****** FRAME 2: DATA ******
                -- data (8 bits: orden de envío real="76543210", orden de envío lógico="01234567")
                when edo4 => --> revisar (0: ack, 1: not ack), y transmitir, o no
                -- edo. siguiente
                if bits < 7 then
                    if (bits = 0 and i_sda = '0') then
                        presente <= edo4;
                    else
                        presente <= e_slv_error;
                    end if;
                    bits <= bits + 1;
                else
                    presente <= edo5;
                    bits <= 0;
                end if;
                -- entradas / salidas
                sel_scl <= "00"; -- scl
                sel_sda <= "01"; -- datos
                o_sda <= datos;

                when edo5 => -- ack o _ack
                    -- edo. siguiente
                    if ena = '0' then
                        presente <= edo6;
                    else
                        presente <= edo4;
                    end if;
                    -- entradas / salidas
                    sel_scl <= "00"; -- scl
                    sel_sda <= "01"; -- datos
                    o_sda <= 'Z';
                
                when edo6 => -- STOP
                    -- edo. siguiente
                    if i_sda = '0' then
                        presente <= edo0;
                    else
                        presente <= e_slv_error;
                    end if;
                    -- entradas / salidas
                    sel_scl <= "01";
                    sel_sda <= "10"; -- not dcl

                when e_slv_error =>
                    -- edo. siguiente
                    presente <= edo0;
                    -- entradas / salidas
                    o_slave_error <= '1';

                
            end case;
        end if;
    end process;
end architecture;