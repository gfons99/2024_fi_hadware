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

        i_datos: in std_logic;
        i_sda: in std_logic;
        -- salidas:
        sel_scl: out std_logic_vector(1 downto 0) := "01"; -- 00: scl    -- 01: '1'
        sel_sda: out std_logic_vector(1 downto 0) := "01"; -- 00: dcl    -- 01: '1' o -- 10: datos -- 11: not dcl

        o_datos:out std_logic;
        o_sda: out std_logic := '1';
        o_slave_error: out std_logic
    );
end entity;

architecture frgm of i2c_fsm is 
    type estados is(edo0,edo1,edo2,edo3,edo_write,edo_ack2,edo_espera_read,edo_read,edo_stop,edo_slv_error);
    signal presente: estados := edo0;
    signal bits: integer range 0 to 7 := 0;
    signal rw: std_logic;

begin
    process(dcl, scl)
    begin
        if rst = '1' then
            presente <= edo0;
        elsif rising_edge(dcl) then
            case presente is
                when edo0 => -- READY
                    -- edo. siguiente
                    if ena = '0' then
                        presente <= edo0;
                    else
                        presente <= edo1;
                    end if;
                    -- entradas / salidas
                    sel_scl <= "01"; -- HIGH
                    sel_sda <= "01"; -- HIGH

                when edo1 => -- START
                    -- edo. siguiente
                    presente <= edo2;
                    -- entradas / salidas
                    sel_scl <= "01"; -- HIGH
                    sel_sda <= "00"; -- dcl

                -- ****** FRAME 1: SLAVE RECEIVER ADDRESS & RW******
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
                    sel_sda <= "10"; -- datos
                    o_sda <= i_datos;

                when edo3 => -- ACK1
                    -- edo. siguiente
                    if i_sda = '0' then -- (r/_w): '1' read, '0' write
                        presente <= edo_write;
                    else
                        presente <= edo_espera_read;
                    end if;
                    -- entradas / salidas
                    sel_scl <= "00"; -- scl
                    sel_sda <= "10"; -- datos
                    o_sda <= 'Z';
                    rw <= i_sda;


                -- ****** FRAME 2: WRITE DATA ******
                -- data (8 bits: orden de envío real="76543210", orden de envío lógico="01234567")
                when edo_write => --> revisar (0: ack, 1: not ack), y transmitir, o no
                    -- edo. siguiente
                    if bits < 7 then
                        if (bits = 0 and i_sda = '0') then
                            presente <= edo_write;
                        else
                            presente <= edo_slv_error;
                        end if;
                        bits <= bits + 1;
                    else
                        presente <= edo_ack2;
                        bits <= 0;
                    end if;
                    -- entradas / salidas
                    sel_scl <= "00"; -- scl
                    sel_sda <= "10"; -- datos
                    o_sda <= i_datos;

                when edo_ack2 => -- ACK2
                    -- edo. siguiente
                    if ena = '0' then
                        presente <= edo_stop;
                    else
                        presente <= edo_write;
                    end if;
                    -- entradas / salidas
                    sel_scl <= "00"; -- scl
                    sel_sda <= "10"; -- datos
                    o_sda <= 'Z';

                when edo_espera_read => -- ESPERA
                    -- edo. siguiente
                    if i_sda = '0' then
                        presente <= edo_read;
                    else
                        presente <= edo_slv_error;
                    end if;
                    -- entradas / salidas
                    sel_scl <= "00"; -- scl
                    sel_sda <= "10"; -- datos
                    o_sda <= 'Z';
                
                -- ****** FRAME 2: READ DATA ******
                -- data (8 bits: orden de recepción real="76543210", orden de recepción lógico="01234567")
                when edo_read => --> revisar (0: ack, 1: not ack), y transmitir, o no
                    -- edo. siguiente
                    if bits < 7 then
                        presente <= edo_read;
                        bits <= bits + 1;
                    else
                        if ena = '0' then
                            presente <= edo_stop;
                        else
                            presente <= edo_espera_read;
                        end if;
                        bits <= 0;
                    end if;
                    -- entradas / salidas
                    sel_scl <= "00"; -- scl
                    sel_sda <= "10"; -- datos
                    o_datos <= i_sda;
                
                -- ****** FIN ******
                when edo_stop => -- STOP
                    -- edo. siguiente
                    if i_sda = '0' then
                        presente <= edo0;
                    else
                        presente <= edo_slv_error;
                    end if;
                    -- entradas / salidas
                    sel_scl <= "01"; -- HIGH
                    sel_sda <= "11"; -- not dcl

                when edo_slv_error =>
                    -- edo. siguiente
                    presente <= edo0;
                    -- entradas / salidas
                    o_slave_error <= '1';
                    bits <= 0;

                
            end case;
        end if;
    end process;
end architecture;