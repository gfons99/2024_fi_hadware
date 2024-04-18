-- ****************************************
-- tittle:	Controlador para el ADS1115
-- author:	F.R., G.M.
-- date: 2024-04
-- description: Máquina de estados de Moore
-- ****************************************

library ieee;
use ieee.std_logic_1164.all;

entity fsm_i2c_ads1115 is
    port (
        -- entradas:
        clk, scl: in std_logic;
        rst, ena: in std_logic;

        data: in std_logic; -- dirección del registro analógico A3-A0 (bits P1:P0)
        
        i_sda: in std_logic;
        -- salidas:
        sel_scl: out std_logic := '1';
        o_sda: out std_logic := '1';
        o_slave_error: out std_logic;
    );
end entity;

architecture frgm of fsm_i2c_ads1115 is 

type estados is(edo0,edo1,edo2,edo3,edo4,edo5,edo6,edo7,edo8,edo9,edo10,edo12,edo13,edo14,e_slv_error);

signal presente: estados := edo0;
signal bits : integer range 0 to 7 := 0;

constant dir_slave: in std_logic_vector(6 downto 0) := "1001000"; -- dirección del esclavo

begin
    process(clk, scl)
    begin
        if falling_edge(clk) then
            case presente is
                when edo0 => -- READY 1
                    -- edo. siguiente
                    if ena = '0' then
                        presente <= edo0;
                    elsif ena = '1' and scl '0' then
                        presente <= edo1;
                    else
                        presente <= edo0;
                    end if;
                    -- entradas / salidas
                    o_sda <= '1';
                when edo1 => -- espera
                    -- edo. siguiente
                    presente <= edo2;

                when edo2 => -- START 1
                    -- edo. siguiente
                    presente <= edo3;
                    -- entradas / salidas
                    o_sda <= '0';
                    sel_scl <= '0';
                
                -- ****** FRAME 1: SLAVE RECEIVER ADDRESS ******
                when edo3 => -- slave receiver address (7 bits: orden de envío real="6543210", orden de envío lógico="0123456")
                    if bits < 6 then
                        presente <= edo4;
                        bits <= bits + 1;
                    else
                        presente <= edo5;
                        bits <= 0;
                    end if;
                    -- entradas / salidas
                    sda_o <= dir_slave(bits);
                when edo4 => -- espera
                    -- edo. siguiente
                    presente <= edo3;
                
                when edo5 => -- (r/_w): '1' read, '0' write
                    -- edo. siguiente
                    presente <= edo6;
                    -- entradas / salidas
                    o_sda <= '0'; -- write
                when edo6 => -- espera
                    -- edo. siguiente
                    presente <= edo7;
                    -- entradas / salidas
                    o_sda = 'Z';
                
                when edo7 => -- ack o _ack del esclavo al maestro
                    -- edo. siguiente
                    if i_sda = '0' then -- acknowledge
                        presente <= edo9;
                    elsif i_sda = '1' then -- not acknowledge
                        presente <= e_slv_error;
                    end if;
                    -- entradas / salidas
                when edo8 => -- espera
                    -- edo. siguiente
                    presente <= edo9;

                -- ****** FRAME 2: DATA ******
                when edo9 => -- data (8 bits: orden de envío real="76543210", orden de envío lógico="01234567")
                -- edo. siguiente
                if bits < 7 then
                    presente <= edo10;
                    bits <= bits + 1;
                else
                    presente <= edo11;
                    bits <= 0;
                end if;
                -- entradas / salidas
                sda_o <= data;
                when edo10 => -- espera
                    -- edo. siguiente
                    presente <= edo9;
                    -- entradas / salidas
                    o_sda = 'Z';
                
                when edo11 => -- ack o _ack del esclavo al maestro
                    -- edo. siguiente
                    if i_sda = '0' then -- acknowledge
                        presente <= edo12;
                    elsif i_sda = '1' then -- not acknowledge
                        presente <= e_slv_error;
                    end if;
                    -- entradas / salidas
                when edo12 => -- espera
                    -- edo. siguiente
                    if ena = '0' then
                        presente <= edo13;
                    else
                        presente <= edo11;
                    end if;
                    
                when edo13 => -- STOP 1
                    -- edo. siguiente
                    presente <= edo14;
                    -- entradas / salidas
                    o_sda <= '0';
                when edo14 => -- STOP 2
                    -- edo. siguiente
                    presente <= edo0;
                    -- entradas / salidas
                    o_sda <= '1';
                when e_slv_error =>
                    -- edo. siguiente
                    presente <= edo0;
                    -- entradas / salidas
                    o_slave_error <= '1';
            end case;
        end if;
    end process;
end architecture;