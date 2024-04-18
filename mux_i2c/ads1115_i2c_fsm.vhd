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
        sw_adc_ch: in std_logic_vector(1 downto 0);

        -- salidas:
        ena: out std_logic;
        datos: out std_logic;
    );
end entity;

architecture frgm of i2c_fsm is 
    type estados is(edo0,edo1,edo2,edo3,edo4,edo5,edo6,e_slv_error);
    signal presente: estados := edo0;
    signal bits : integer range 0 to 7 := 0;
    constant mem_dir_slave_rw: std_logic_vector(6 downto 0) := "1001000"; -- dirección del esclavo
    signal mem_dir_adc: std_logic_vector(7 downto 0);
    signal t_espera: integer := 3124999;

begin
    process(dcl, scl)
    begin
        if rst = '1' then
            presente <= edo0;
        elsif rising_edge(dcl) then
            case presente is
                when edo0 => -- READY
                    -- edo. siguiente
                    presente <= edo1;
                    -- entradas / salidas
                    ena <= '1';

                when edo1 => -- ESPERA: START
                    -- edo. siguiente
                    presente <= edo2;
                    -- entradas / salidas

                -- ****** FRAME 1: SLAVE RECEIVER ADDRESS & RW******
                when edo2 => -- slave receiver address (8 bits: orden de envío real="6543210 & rw", orden de envío lógico="0123456  & rw")
                    -- edo. siguiente
                    if bits < 7 then
                        presente <= edo2;
                        bits <= bits + 1;
                    else
                        presente <= edo3;
                        bits <= 0;
                    end if;
                    -- entradas / salidas
                    if bits = 7 then
                        datos <= '0'; -- (r/_w): '1' read, '0' write
                    else
                        datos <= mem_dir_slave_rw(bits);
                    end if;
                when edo3 => -- ESPERA: ack o _ack
                    -- edo. siguiente
                    presente <= edo4;
                    -- entradas / salidas
                
                -- ****** FRAME 2: DATA ******
                -- data (8 bits: orden de envío real="76543210", orden de envío lógico="01234567")
                when edo4 => --> revisar (0: ack, 1: not ack), y transmitir, o no
                    -- edo. siguiente
                    if bits < 7 then
                        presente <= edo4;
                        bits <= bits + 1;
                    else
                        presente <= edo5;
                        bits <= 0;
                    end if;
                    -- entradas / salidas
                    mem_dir_adc <= "000000" and sw_adc_ch;
                    datos <= mem_dir_slave_rw(bits);
                
                when edo5 => -- ESPERA: ack o _ack
                    -- edo. siguiente
                    if bits < 7 then
                        presente <= edo4;
                        bits <= bits + 1;
                    else
                        presente <= edo5;
                        bits <= 0;
                    end if;
                    -- entradas / salidas
                    ena <= '0';
                
                when edo6 => -- ESPERA: STOP
                    -- edo. siguiente
                    presente <= edo7;
                    -- entradas / salidas
                
                -- ****** ESPERA ANTES DE LEER ******
                when edo7  => -- ESPERA: ADC 
                    -- f=3.125 MHz : T = 0.32 uS, por lo tanto 1 s = 3,125,000
                    -- edo. siguiente
                    if t_espera = 0 then
                        presente <= edo8;
                        t_espera <= 3124999;
                    else
                        presente <= edo7;
                        t_espera <= t_espera - 1;
                    end if;
                    -- entradas / salidas

                when edo8 => -- READY
                    -- edo. siguiente
                    presente <= edo9;
                    -- entradas / salidas
                    ena <= '1';

                when edo9 => -- ESPERA: START
                    -- edo. siguiente
                    presente <= edo10;
                    -- entradas / salidas

                -- ****** FRAME 3: SLAVE RECEIVER ADDRESS & RW******
                when edo10 => -- slave receiver address (8 bits: orden de envío real="6543210 & rw", orden de envío lógico="0123456  & rw")
                    -- edo. siguiente
                    if bits < 7 then
                        presente <= edo10;
                        bits <= bits + 1;
                    else
                        presente <= edo11;
                        bits <= 0;
                    end if;
                    -- entradas / salidas
                    datos <= mem_dir_slave_rw(bits);

                when edo11 => -- ESPERA: ack o _ack
                    -- edo. siguiente
                    presente <= edo12;
                    -- entradas / salidas
                
                -- ****** FRAME 4: ADC D15-D8 ******
                -- data (8 bits: orden de envío real="76543210", orden de envío lógico="01234567")
                when edo4 => --> revisar (0: ack, 1: not ack), y transmitir, o no
                    -- edo. siguiente
                    if bits < 7 then
                        presente <= edo4;
                        bits <= bits + 1;
                    else
                        presente <= edo5;
                        bits <= 0;
                    end if;
                    -- entradas / salidas
                    mem_dir_adc <= "000000" and sw_adc_ch;
                    datos <= mem_dir_slave_rw(bits);
                
                when edo5 => -- ESPERA: ack o _ack
                    -- edo. siguiente
                    if bits < 7 then
                        presente <= edo4;
                        bits <= bits + 1;
                    else
                        presente <= edo5;
                        bits <= 0;
                    end if;
                    -- entradas / salidas
                    ena <= '0';
                
                when edo6 => -- ESPERA: STOP
                    -- edo. siguiente
                    presente <= edo7;
                    -- entradas / salidas
                
            end case;
        end if;
    end process;
end architecture;