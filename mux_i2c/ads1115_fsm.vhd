-- ****************************************
-- tittle:	Controlador para el ADS1115
-- author:	F.R., G.M.
-- date: 2024-04
-- description: Máquina de estados de Moore
-- ****************************************

library ieee;
use ieee.std_logic_1164.all;

entity ads1115_fsm is
    port (
        -- entradas:
        dcl: in std_logic;
        sw_adc_ch: in std_logic_vector(1 downto 0);
        rst: in std_logic;
        i_lectura: in std_logic;

        -- salidas:
        ena: out std_logic;
        o_escritura: out std_logic;
        adc_16b: out std_logic_vector(15 downto 0)
    );
end entity;

architecture frgm of ads1115_fsm is 
    type estados is(edo_ready,edo_espera_start,ed_dir_slv,edo_ack1,edo_dir_adc,edo_ack2,espera_stop,espera_adc,edo_ready_f345,edo_espera_start_f345,ed_dir_slv_f345,edo_ack3,edo_read_adc_15_8,edo_ack4,edo_read_adc_7_0,edo_espera_stop_f345);
    signal presente: estados := edo_ready;
    signal bits : integer range 0 to 7 := 0;
    signal t_espera: integer := 3124999;

    -- datos:
    constant mem_dir_slave_rw: std_logic_vector(6 downto 0) := "1001000"; -- dirección del esclavo
    signal mem_dir_adc: std_logic_vector(7 downto 0);
    signal mem_adc_16b: std_logic_vector(15 downto 0);
    

begin
    process(dcl)
    begin
        if rst = '1' then
            presente <= edo_ready;
        elsif rising_edge(dcl) then
            case presente is
                when edo_ready => -- READY
                    -- edo. siguiente
                    presente <= edo_espera_start;
                    -- entradas / salidas
                    ena <= '1';

                when edo_espera_start => -- START
                    -- edo. siguiente
                    presente <= ed_dir_slv;
                    -- entradas / salidas

                -- ****** FRAME 1: SLAVE RECEIVER ADDRESS & RW******
                when ed_dir_slv => -- slave receiver address (8 bits: orden de envío real="6543210 & rw", orden de envío lógico="0123456  & rw")
                    -- edo. siguiente
                    if bits < 7 then
                        presente <= ed_dir_slv;
                        bits <= bits + 1;
                    else
                        presente <= edo_ack1;
                        bits <= 0;
                    end if;
                    -- entradas / salidas
                    if bits = 7 then
                        o_escritura <= '0'; -- (r/_w): '1' read, '0' write
                    else
                        o_escritura <= mem_dir_slave_rw(bits);
                    end if;
                
                when edo_ack1 => -- ESPERA: ack o _ack
                    -- edo. siguiente
                    presente <= edo_dir_adc;
                    -- entradas / salidas
                
                -- ****** FRAME 2: DATA ******
                -- data (8 bits: orden de envío real="76543210", orden de envío lógico="01234567")
                when edo_dir_adc => --> revisar (0: ack, 1: not ack), y transmitir, o no
                    -- edo. siguiente
                    if bits < 7 then
                        presente <= edo_dir_adc;
                        bits <= bits + 1;
                    else
                        presente <= edo_ack2;
                        bits <= 0;
                    end if;
                    -- entradas / salidas
                    mem_dir_adc <= "000000" and sw_adc_ch;
                    o_escritura <= mem_dir_slave_rw(bits);
                
                when edo_ack2 => -- ESPERA: ack o _ack
                    -- edo. siguiente
                    presente <= espera_stop;
                    -- entradas / salidas
                    ena <= '0';
                
                when espera_stop => -- STOP
                    -- edo. siguiente
                    presente <= espera_adc;
                    -- entradas / salidas
                
                when espera_adc =>
                    -- edo. siguiente
                    if t_espera = 0 then
                        t_espera <= 3124999;
                        presente <= edo_ready_f345;
                    else
                        t_espera <= t_espera - 1;
                        presente <= espera_adc;
                    end if;
                    -- entradas / salidas
                
                when edo_ready_f345 => -- READY
                    -- edo. siguiente
                    presente <= edo_espera_start_f345;
                    -- entradas / salidas
                    ena <= '1';

                when edo_espera_start_f345 => -- START
                    -- edo. siguiente
                    presente <= ed_dir_slv_f345;
                    -- entradas / salidas

                -- ****** FRAME 3: SLAVE RECEIVER ADDRESS & RW******
                when ed_dir_slv_f345 => -- slave receiver address (8 bits: orden de envío real="6543210 & rw", orden de envío lógico="0123456  & rw")
                    -- edo. siguiente
                    if bits < 7 then
                        presente <= ed_dir_slv_f345;
                        bits <= bits + 1;
                    else
                        presente <= edo_ack3;
                        bits <= 0;
                    end if;
                    -- entradas / salidas
                    if bits = 7 then
                        o_escritura <= '1'; -- (r/_w): '1' read, '0' write
                    else
                        o_escritura <= mem_dir_slave_rw(bits);
                    end if;
                
                when edo_ack3 => -- ESPERA: ack o _ack
                    -- edo. siguiente
                    if bits < 1 then
                        presente <= edo_ack3;
                        bits <= bits + 1;
                    else
                        presente <= edo_read_adc_15_8;
                        bits <= 0;
                    end if;
                    -- entradas / salidas 
                
                -- ****** FRAME 4: ADC reading from bit 15 to bit 8 ******
                when edo_read_adc_15_8 =>
                    if bits < 7 then
                        presente <= edo_read_adc_15_8;
                        bits <= bits + 1;
                    else
                        presente <= edo_ack4;
                        bits <= 8;
                    end if;
                    -- entradas / salidas 
                    mem_adc_16b(bits) <= i_lectura;

                when edo_ack4 => -- ESPERA: ack o _ack
                    -- edo. siguiente
                    presente <= edo_read_adc_7_0;
                    -- entradas / salidas

                when edo_read_adc_7_0 =>
                    -- edo. siguiente
                    if bits < 15 then
                        presente <= edo_read_adc_7_0;
                        bits <= bits + 1;
                    else
                        presente <= edo_ack4;
                        bits <= 0;
                    end if;
                    -- entradas / salidas
                    if bits = 15 then
                        ena <= '0';
                    end if;
                
                when edo_espera_stop_f345 =>
                    -- edo. siguiente
                    if t_espera = 0 then
                        t_espera <= 3124999;
                        presente <= edo_ready;
                    else
                        t_espera <= t_espera - 1;
                        presente <= edo_espera_stop_f345;
                    end if;
                    -- entradas / salidas       
                    
            end case;
        end if;
    end process;
end architecture;