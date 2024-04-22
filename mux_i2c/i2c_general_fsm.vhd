-- ****************************************
-- tittle:	Controlador para el ADS1115
-- author:	F.R., G.M.
-- date: 2024-04
-- description: Máquina de estados de Moore
-- ****************************************

library ieee;
use ieee.std_logic_1164.all;

entity i2c_general_fsm is
    port (
        -- entradas:
        dcl: in std_logic;
        rst, ena: in std_logic;

        i_write: in std_logic;
        i_sda: in std_logic;
        -- salidas:
        sel_scl: out std_logic_vector(1 downto 0) := "01"; -- 00: scl    -- 01: '1'
        sel_sda: out std_logic_vector(1 downto 0) := "01"; -- 00: dcl    -- 01: '1' o -- 10: datos -- 11: not dcl

        o_read:out std_logic;
        o_sda: out std_logic := '1';

        o_slave_error: out std_logic
    );
end entity;

architecture frgm of i2c_general_fsm is 
    type estados is(edo_idle,edo_start,edo_frame1,edo_ack1,edo_write,edo_ack2_write,edo_read,edo_ack2_read,edo_stop);
    signal presente: estados := edo_idle;
    signal bits: integer range 0 to 7 := 0;
    signal rw: std_logic;

begin
    process(dcl)
    begin
        if rst = '1' then
            presente <= edo_idle;
        elsif rising_edge(dcl) then
            case presente is
                when edo_idle =>
                    -- edo. siguiente
                    if ena = '0' then
                        presente <= edo_idle;
                    else
                        presente <= edo_start;
                    end if;
                    -- relojes
                    sel_scl <= "01"; -- HIGH
                    sel_sda <= "01"; -- HIGH
                    -- entradas / salidas
                when edo_start =>
                    -- edo. siguiente
                        presente <= edo_frame1;
                    -- relojes
                    sel_scl <= "01"; -- HIGH
                    sel_sda <= "00"; -- DCL_CLK
                    -- entradas / salidas

                -- ****** FRAME 1: SLAVE RECEIVER ADDRESS & RW ******
                when edo_frame1 => -- (8 bits: orden de envío real="6543210 & rw", orden de envío lógico="0123456  & rw")
                    -- edo. siguiente
                    if bits < 7 then
                        presente <= edo_frame1;
                        bits <= bits + 1;
                    else
                        presente <= edo_ack1;
                        bits <= 0;
                    end if;
                    -- relojes
                    sel_scl <= "00"; -- SCL_CLK
                    sel_sda <= "10"; -- datos
                    -- entradas / salidas
                    o_sda <= i_write;
                    if bits = 7 then
                        rw <= i_sda;
                    end if;
                when edo_ack1 =>
                    -- edo. siguiente (i_sda es el acknowledge del esclavo al maestro)
                    if i_sda = '0' and rw = '0' then
                        presente <= edo_write;
                    elsif i_sda = '0' and rw = '1' then
                        presente <= edo_read;
                    else 
                        presente <= edo_stop;
                    end if;
                    -- relojes
                    sel_scl <= "00"; -- SCL_CLK
                    sel_sda <= "10"; -- datos
                    -- entradas / salidas
                    o_sda <= 'Z';
                    o_slave_error <= i_sda;

                -- ****** FRAME 2: WRITE DATA ******
                -- data (8 bits: orden de envío real="76543210", orden de envío lógico="01234567")
                when edo_write =>
                    -- edo. siguiente
                    if bits < 7 then
                        presente <= edo_write;
                        bits <= bits + 1;
                    else
                        presente <= edo_ack2_write;
                        bits <= 0;
                    end if;
                    -- relojes
                    sel_scl <= "00"; -- SCL_CLK
                    sel_sda <= "10"; -- datos
                    -- entradas / salidas
                    o_sda <= i_write;
                when edo_ack2_write =>
                    -- edo. siguiente
                    if i_sda = '1' or ena = '0' then
                        presente <= edo_stop;
                    else
                        presente <= edo_write;
                    end if;
                    -- relojes
                    sel_scl <= "00"; -- SCL_CLK
                    sel_sda <= "10"; -- datos
                    -- entradas / salidas
                    o_sda <= 'Z';
                    o_slave_error <= i_sda;
                
                -- ****** FRAME 2: READ DATA ******
                -- data (8 bits: orden de recepción real="76543210", orden de recepción lógico="01234567")
                when edo_read =>
                    -- edo. siguiente
                    if bits < 7 then
                        presente <= edo_read;
                        bits <= bits + 1;
                    else
                        presente <= edo_ack2_read;
                        bits <= 0;
                    end if;
                    -- relojes
                    sel_scl <= "00"; -- SCL_CLK
                    sel_sda <= "10"; -- datos
                    -- entradas / salidas
                    o_sda <= 'Z';
                    o_read <= i_sda;
                when edo_ack2_read =>
                    -- edo. siguiente
                    if i_sda = '1' or ena = '0' then
                        presente <= edo_stop;
                    else
                        presente <= edo_read;
                    end if;
                    -- relojes
                    sel_scl <= "00"; -- SCL_CLK
                    sel_sda <= "10"; -- datos
                    -- entradas / salidas
                    o_sda <= '0';
                    o_slave_error <= i_sda;
                
                -- ****** FIN DE I2C ******
                when edo_stop =>
                    -- edo. siguiente
                    presente <= edo_idle;
                    -- relojes
                    sel_scl <= "01"; -- HIGH
                    sel_sda <= "11"; -- NOT DCL
                    -- entradas / salidas
                    
            end case;
        end if;
    end process;
end architecture;