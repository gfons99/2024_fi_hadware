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
        clk, rst: in std_logic;

        dir_slave: in std_logic; -- dirección del esclavo
        sda_i: in std_logic;

        dir_reg_p: in std_logic; -- dirección del registro analógico A3-A0 (bits P1:P0)
        adc_16: in std_logic;
        
        -- salidas:
        o_scl, o_Sda; out std_logic;
    );
end entity;

architecture frgm of fsm_i2c_ads1115 is 

type estados is(e0,e1,e2,e3,e4,e5,e6,e7,e8,e9,e10,e11,e12,e13,e14,e15,e16);
signal presente: estados := e0;
signal bits : integer range 0 to 7 := 0;

begin
    process(clk, rst, sda_i)
    begin
        if rising_edge(clk) then
            case presente is
                -- ****** FRAME 1 ******
                -- start scl: 1 a tic-tac; sda_o: 1 a 0;
                when e0 =>
                    -- edo. siguiente
                    presente <= e1;
                    -- entradas / salidas
                    e_scl <= '0'; e_sda <= '1'; sda_o<='0';
                -- slave receiver address (7 bits)
                when e1 =>
                    -- edo. siguiente
                    if bits <= 6 then
                        presente <= e1;
                        bits <= bits + 1;
                    else
                        presente <= e2;
                        bits <= 0;
                    end if;
                    -- entradas / salidas
                    e_sda <= '1'; sda_o <= dir_slave;
                -- r/_w (1 bit)
                when e2 =>
                    -- edo. siguiente
                    presente <= e3;
                    -- entradas / salidas
                    e_sda <= '1'; sda_o <= '0'; -- write
                -- ack o _ack del esclavo al maestro
                when e3 =>
                    -- edo. siguiente
                    if sda_i = '0' then
                        presente <= e4;
                    elsif sda_i = '1' then
                        presente <= e4;
                    elsif sda_i = 'Z' then
                        presente <= e3;
                    end if;
                    -- entradas / salidas
                
                -- ****** FRAME 2 ******
                -- data: Elegir un canal analógico
                when e4 =>
                    -- edo. siguiente
                    if bits <= 7 then
                        presente <= e4;
                        bits <= bits + 1;
                    else
                        presente <= e5;
                        bits <= 0;
                    end if;
                    -- entradas / salidas
                    e_sda <= '1'; sda_o <= dir_reg_p;
                -- ack o _ack del esclavo al maestro
                when e5 =>
                    -- edo. siguiente
                    if sda_i = '0' then
                        presente <= e6;
                    elsif sda_i = '1' then
                        presente <= e6;
                    elsif sda_i = 'Z' then
                        presente <= e5;
                    end if;
                    -- entradas / salidas
                
                -- stop scl: tic-tac a 1; sda_o: 0 a 1;
                when e6 =>
                    -- edo. siguiente
                    presente <= e7;
                    -- entradas / salidas
                    e_scl <= '1'; sda_o<='1';
                
                -- TIEMPO DE ESPERA*********
                when e7 =>
                
                -- ****** FRAME 3 ******
                -- start scl: 1 a tic-tac; sda_o: 1 a 0;
                when e8 =>
                    -- edo. siguiente
                    presente <= e9;
                    -- entradas / salidas
                    e_scl <= '0'; e_sda <= '1'; sda_o<='0';
                -- slave receiver address (7 bits)
                when e9 =>
                    -- edo. siguiente
                    if bits <= 6 then
                        presente <= e9;
                        bits <= bits + 1;
                    else
                        presente <= e10;
                        bits <= 0;
                    end if;
                    -- entradas / salidas
                    e_sda <= '1'; sda_o <= dir_slave;
                -- r/_w (1 bit)
                when e10 =>
                    -- edo. siguiente
                    presente <= e9;
                    -- entradas / salidas
                    e_sda <= '1'; sda_o <= '1'; -- read
                -- ack o _ack del esclavo al maestro
                when e11 =>
                    -- edo. siguiente
                    if sda_i = '0' then
                        presente <= e12;
                    elsif sda_i = '1' then
                        presente <= e12;
                    elsif sda_i = 'Z' then
                        presente <= e11;
                    end if;
                    -- entradas / salidas
                
                -- ****** FRAME 4 ******
                -- Leer el registro de 16 bits (del 15 al 0, en ese orden)
                when e12 =>
                    -- edo. siguiente
                    if bits <= 7 then
                        presente <= e12;
                        bits <= bits + 1;
                    else
                        presente <= e13;
                        bits <= 0;
                    end if;
                    -- entradas / salidas
                    adc_16 <= sda_i;
                -- ack o _ack del esclavo al maestro
                when e13 =>
                    -- edo. siguiente
                    if sda_i = '0' then
                        presente <= e14;
                    elsif sda_i = '1' then
                        presente <= e14;
                    elsif sda_i = 'Z' then
                        presente <= e13;
                    end if;
                    -- entradas / salidas
                
                    -- ****** FRAME 5 ******
                -- Leer el registro de 16 bits (del 15 al 0, en ese orden)
                when e14 =>
                    -- edo. siguiente
                    if bits <= 7 then
                        presente <= e14;
                        bits <= bits + 1;
                    else
                        presente <= e15;
                        bits <= 0;
                    end if;
                    -- entradas / salidas
                    adc_16 <= sda_i;
                -- ack o _ack del esclavo al maestro
                when e15 =>
                    -- edo. siguiente
                    if sda_i = '0' then
                        presente <= e16;
                    elsif sda_i = '1' then
                        presente <= e16;
                    elsif sda_i = 'Z' then
                        presente <= e15;
                    end if;
                    -- entradas / salidas
                
                -- stop scl: tic-tac a 1; sda_o: 0 a 1;
                when e16 =>
                    -- edo. siguiente
                    presente <= e0;
                    -- entradas / salidas
                    e_scl <= '1'; sda_o<='1';


            end case;
        end if;
    end process;
end architecture;