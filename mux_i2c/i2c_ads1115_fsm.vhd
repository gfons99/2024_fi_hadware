-- ****************************************
-- tittle:    Controlador para el ADS1115
-- author:    F.R., G.M.
-- date: 2024-04
-- description: Máquina de estados de Moore
-- ****************************************

library ieee;
use ieee.std_logic_1164.all;

entity i2c_ads1115_fsm is
    port (
        -- entradas:
        dcl: in std_logic;
        sw_adc_ch: in std_logic_vector(1 downto 0);
        rst: in std_logic;
        i_read: in std_logic;

        -- salidas:
        o_ena: out std_logic;
        o_write: out std_logic;
        o_show_edo_frame: out integer range 1 to 5;
        adc_16b: out std_logic_vector(15 downto 0)
    );
end entity;

architecture frgm of i2c_ads1115_fsm is 
    type estados is(
        -- ESCRITURA / CONFIGURACIÓN
        edo_wr_iddle,
        edo_wr_start,
        edo_wr_dir_slv,
        edo_wr_ack1,

        edo_wr_addr_p_reg,
        edo_wr_ack2,

        edo_wr_config_15_8,
        edo_wr_ack3,
        
        edo_wr_config_7_0,
        edo_wr_ack4,
        edo_wr_stop,
        
        -- LECTURA
        edo_rd_iddle,
        edo_rd_start_f12,
        edo_rd_dir_slv_f12,
        edo_rd_ack1,

        edo_rd_addr_p_reg,
        edo_rd_ack2,
        edo_rd_stop_f12,

        edo_rd_iddle_f345,
        edo_rd_start_f345,
        edo_rd_dir_slv_f345,
        edo_rd_ack3,

        edo_rd_adc_15_8,
        edo_rd_ack_4,
        
        edo_rd_adc_7_0,
        edo_rd_ack_5,
        edo_rd_stop_f345
        );
    signal presente: estados := edo_wr_start;
    signal bits: integer range 0 to 15 := 0;

    -- signal mem_rd_adc: std_logic_vector(15 downto 0);

    -- datos:
    constant mem_dir_slave: std_logic_vector(6 downto 0) := "1001000"; -- dirección del esclavo
    constant mem_addr_p_reg_rd: std_logic_vector(7 downto 0) := "00000000"; -- read from register [P1:P0]="00"
    constant mem_addr_p_reg_wr: std_logic_vector(7 downto 0) := "00000001"; -- config register [P1:P0]="01"
    constant mem_config_reg: std_logic_vector(15 downto 0) := "1100000110000011"; -- config register [P1:P0]="01"

begin
    process(dcl)
    begin
        if rst = '1' then
            presente <= edo_wr_start;
            o_show_edo_frame <= 1;
        elsif rising_edge(dcl) then
            case presente is
                -- ESCRITURA / CONFIGURACIÓN
                -- ****** FRAME 1: SLAVE RECEIVER ADDRESS & RW ******
                when edo_wr_iddle =>
                -- edo. siguiente
                presente <= edo_wr_start;
                -- entradas / salidas
                o_ena <= '1';
                o_show_edo_frame <= 1;
                when edo_wr_start =>
                    -- edo. siguiente
                    presente <= edo_wr_dir_slv;
                    -- entradas / salidas
                when edo_wr_dir_slv => -- slave receiver address (8 bits: orden de envío real="6543210 & rw", orden de envío lógico="0123456  & rw")
                    -- edo. siguiente
                    if bits < 7 then
                        presente <= edo_wr_dir_slv;
                        bits <= bits + 1;
                    else
                        presente <= edo_wr_ack1;
                        bits <= 0;
                    end if;
                    -- entradas / salidas
                    if bits = 7 then
                        o_write <= '0'; -- (r/_w): '1' read, '0' write
                    else
                        o_write <= mem_dir_slave(bits);
                    end if;
                when edo_wr_ack1 => -- ESPERA: ack o _ack
                    -- edo. siguiente
                    presente <= edo_wr_addr_p_reg;
                    -- entradas / salidas
                
                -- ****** FRAME 2: ADDRESS POINTER REGISTER ******
                when edo_wr_addr_p_reg => -- data (8 bits: orden de envío real="76543210", orden de envío lógico="01234567")
                    if bits < 7 then
                        presente <= edo_wr_addr_p_reg;
                        bits <= bits + 1;
                    else
                        presente <= edo_wr_ack2;
                        bits <= 0;
                    end if;
                    -- entradas / salidas
                    o_write <= mem_addr_p_reg_wr(bits);
                    o_show_edo_frame <= 2;
                when edo_wr_ack2 => -- ESPERA: ack o _ack
                    -- edo. siguiente
                    presente <= edo_wr_config_15_8;
                    -- entradas / salidas

                -- ****** FRAME 3: CONFIG BYTE 1 ******
                when edo_wr_config_15_8 => -- data (8 bits: orden de recepción real="76543210", orden de recepción lógico="01234567")
                    if bits < 7 then
                        presente <= edo_wr_config_15_8;
                        bits <= bits + 1;
                    else
                        presente <= edo_wr_ack3;
                        bits <= 8;
                    end if;
                    -- entradas / salidas
                    o_write <= mem_config_reg(bits);
                    o_show_edo_frame <= 3;
                when edo_wr_ack3 => -- ESPERA: ack o _ack
                    -- edo. siguiente
                    presente <= edo_wr_config_7_0;
                    -- entradas / salidas
                    
                -- ****** FRAME 4: CONFIG BYTE 0 ******
                when edo_wr_config_7_0 => -- data (8 bits: orden de recepción real="76543210", orden de recepción lógico="01234567")
                    if bits < 15 then
                        presente <= edo_wr_config_7_0;
                        bits <= bits + 1;
                    else
                        presente <= edo_wr_ack4;
                        bits <= 0;
                    end if;
                    -- entradas / salidas
                    o_write <= mem_config_reg(bits);
                    o_show_edo_frame <= 4;
                when edo_wr_ack4 => -- ESPERA: ack o _ack
                    -- edo. siguiente
                    presente <= edo_wr_stop;
                    -- entradas / salidas
                    o_ena <= '0';
                when edo_wr_stop =>
                -- edo. siguiente
                    presente <= edo_rd_iddle;
                    -- entradas / salidas

                -- LECTURA
                -- ****** FRAME 1: SLAVE RECEIVER ADDRESS & RW ******
                when edo_rd_iddle =>
                -- edo. siguiente
                presente <= edo_rd_start_f12;
                -- entradas / salidas
                o_ena <= '1';
                o_show_edo_frame <= 1;
                when edo_rd_start_f12 =>
                    -- edo. siguiente
                    presente <= edo_rd_dir_slv_f12;
                    -- entradas / salidas
                when edo_rd_dir_slv_f12 => -- slave receiver address (8 bits: orden de envío real="6543210 & rw", orden de envío lógico="0123456  & rw")
                    -- edo. siguiente
                    if bits < 7 then
                        presente <= edo_rd_dir_slv_f12;
                        bits <= bits + 1;
                    else
                        presente <= edo_rd_ack1;
                        bits <= 0;
                    end if;
                    -- entradas / salidas
                    if bits = 7 then
                        o_write <= '0'; -- (r/_w): '1' read, '0' write
                    else
                        o_write <= mem_dir_slave(bits);
                    end if;
                when edo_rd_ack1 => -- ESPERA: ack o _ack
                    -- edo. siguiente
                    presente <= edo_rd_addr_p_reg;
                    -- entradas / salidas
                
                -- ****** FRAME 2: ADDRESS POINTER REGISTER ******
                when edo_rd_addr_p_reg => -- data (8 bits: orden de envío real="76543210", orden de envío lógico="01234567")
                    if bits < 7 then
                        presente <= edo_rd_addr_p_reg;
                        bits <= bits + 1;
                    else
                        presente <= edo_rd_ack2;
                        bits <= 0;
                    end if;
                    -- entradas / salidas
                    o_write <= mem_addr_p_reg_rd(bits);
                    o_show_edo_frame <= 2;
                when edo_rd_ack2 => -- ESPERA: ack o _ack
                    -- edo. siguiente
                    presente <= edo_rd_stop_f12;
                    -- entradas / salidas
                    o_ena <= '0';
                when edo_rd_stop_f12 =>
                    -- edo. siguiente
                    presente <= edo_rd_iddle_f345;
                    -- entradas / salidas
                
                -- ****** FRAME 3: SLAVE RECEIVER ADDRESS & RW ******
                when edo_rd_iddle_f345 =>
                    -- edo. siguiente
                    presente <= edo_rd_start_f345;
                    -- entradas / salidas
                    o_ena <= '1';
                    o_show_edo_frame <= 3;
                when edo_rd_start_f345 =>
                    -- edo. siguiente
                    presente <= edo_rd_dir_slv_f345;
                    -- entradas / salidas
                when edo_rd_dir_slv_f345 => -- slave receiver address (8 bits: orden de envío real="6543210 & rw", orden de envío lógico="0123456  & rw")
                    -- edo. siguiente
                    if bits < 7 then
                        presente <= edo_rd_dir_slv_f345;
                        bits <= bits + 1;
                    else
                        presente <= edo_rd_ack3;
                        bits <= 0;
                    end if;
                    -- entradas / salidas
                    if bits = 7 then
                        o_write <= '1'; -- (r/_w): '1' read, '0' write
                    else
                        o_write <= mem_dir_slave(bits);
                    end if;
                when edo_rd_ack3 => -- ESPERA: ack o _ack
                    -- edo. siguiente
                    presente <= edo_rd_adc_15_8;
                    -- entradas / salidas

                -- ****** FRAME 4: ADC DATA BYTE 1 ******
                when edo_rd_adc_15_8 => -- data (8 bits: orden de recepción real="76543210", orden de recepción lógico="01234567")
                    if bits < 7 then
                        presente <= edo_rd_adc_15_8;
                        bits <= bits + 1;
                    else
                        presente <= edo_rd_ack_4;
                        bits <= 8;
                    end if;
                    -- entradas / salidas
                    adc_16b(bits) <= i_read;
                    o_show_edo_frame <= 4;
                when edo_rd_ack_4 => -- ESPERA: ack o _ack
                    -- edo. siguiente
                    presente <= edo_rd_adc_7_0;
                    -- entradas / salidas
                    
                -- ****** FRAME 5: ADC DATA BYTE 0 ******
                when edo_rd_adc_7_0 => -- data (8 bits: orden de recepción real="76543210", orden de recepción lógico="01234567")
                    if bits < 15 then
                        presente <= edo_rd_adc_7_0;
                        bits <= bits + 1;
                    else
                        presente <= edo_rd_ack_5;
                        bits <= 0;
                    end if;
                    -- entradas / salidas
                    adc_16b(bits) <= i_read;
                    o_show_edo_frame <= 5;
                when edo_rd_ack_5 => -- ESPERA: ack o _ack
                    -- edo. siguiente
                    presente <= edo_rd_stop_f345;
                    -- entradas / salidas
                    o_ena <= '0';
                when edo_rd_stop_f345 =>
                -- edo. siguiente
                    presente <= edo_wr_iddle;
                    -- entradas / salidas
                end case;
        end if;
    end process;
end architecture;