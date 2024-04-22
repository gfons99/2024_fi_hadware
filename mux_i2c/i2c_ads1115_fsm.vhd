-- ****************************************
-- tittle:	Controlador para el ADS1115
-- author:	F.R., G.M.
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
    type estados is(edo_start_f12,edo_dir_slv_f12,edo_ack1,edo_sel_adc,edo_ack2,edo_stop_f12,edo_start_f345,edo_dir_slv_f345,edo_ack3,edo_read_adc_15_8,edo_ack_4,edo_read_adc_7_0,edo_ack_5,edo_stop_f345);
    signal presente: estados := edo_start_f12;
    signal bits : integer range 0 to 15 := 0;
    signal t_espera: integer := 3124999;

    -- datos:
    constant mem_dir_slave: std_logic_vector(6 downto 0) := "1001000"; -- dirección del esclavo
	 constant mem_addr_p_reg: std_logic_vector(5 downto 0) := "000000"; -- dirección del esclavo
    signal mem_dir_adc: std_logic_vector(7 downto 0);
    signal mem_adc_16b: std_logic_vector(15 downto 0);
    

begin
    process(dcl)
    begin
        if rst = '1' then
            presente <= edo_start_f12;
        elsif rising_edge(dcl) then
            case presente is
                -- ****** FRAME 1: SLAVE RECEIVER ADDRESS & RW ******
                when edo_start_f12 =>
                    -- edo. siguiente
                    presente <= edo_dir_slv_f12;
                    -- entradas / salidas
                    o_ena <= '1';
						  o_show_edo_frame <= 1;
                when edo_dir_slv_f12 => -- slave receiver address (8 bits: orden de envío real="6543210 & rw", orden de envío lógico="0123456  & rw")
                    -- edo. siguiente
                    if bits < 7 then
                        presente <= edo_dir_slv_f12;
                        bits <= bits + 1;
                    else
                        presente <= edo_ack1;
                        bits <= 0;
                    end if;
                    -- entradas / salidas
                    if bits = 7 then
                        o_write <= '0'; -- (r/_w): '1' read, '0' write
                    else
                        o_write <= mem_dir_slave(bits);
                    end if;
                when edo_ack1 => -- ESPERA: ack o _ack
                    -- edo. siguiente
                    presente <= edo_sel_adc;
                    -- entradas / salidas
                
                -- ****** FRAME 2: ADDRESS POINTER REGISTER ******
                when edo_sel_adc => -- data (8 bits: orden de envío real="76543210", orden de envío lógico="01234567")
                    if bits < 7 then
                        presente <= edo_sel_adc;
                        bits <= bits + 1;
                    else
                        presente <= edo_ack2;
                        bits <= 0;
                    end if;
                    -- entradas / salidas
                    mem_dir_adc <= mem_addr_p_reg & sw_adc_ch;
                    o_write <= mem_dir_adc(bits);
						  o_show_edo_frame <= 2;
                when edo_ack2 => -- ESPERA: ack o _ack
                    -- edo. siguiente
                    presente <= edo_stop_f12;
                    -- entradas / salidas
                    o_ena <= '0';
                when edo_stop_f12 =>
                    -- edo. siguiente
                    presente <= edo_start_f345;
                    -- entradas / salidas
                -- when edo_espera_adc =>
                --     -- edo. siguiente
                --     if t_espera = 0 then
                --         t_espera <= 3124999;
                --         presente <= edo_start_f345;
                --     else
                --         t_espera <= t_espera - 1;
                --         presente <= edo_espera_adc;
                --     end if;
                --     -- entradas / salidas
                
                -- ****** FRAME 3: SLAVE RECEIVER ADDRESS & RW ******
                when edo_start_f345 =>
                    -- edo. siguiente
                    presente <= edo_dir_slv_f345;
                    -- entradas / salidas
                    o_ena <= '1';
						  o_show_edo_frame <= 3;
                when edo_dir_slv_f345 => -- slave receiver address (8 bits: orden de envío real="6543210 & rw", orden de envío lógico="0123456  & rw")
                    -- edo. siguiente
                    if bits < 7 then
                        presente <= edo_dir_slv_f345;
                        bits <= bits + 1;
                    else
                        presente <= edo_ack3;
                        bits <= 0;
                    end if;
                    -- entradas / salidas
                    if bits = 7 then
                        o_write <= '1'; -- (r/_w): '1' read, '0' write
                    else
                        o_write <= mem_dir_slave(bits);
                    end if;
                when edo_ack3 => -- ESPERA: ack o _ack
                    -- edo. siguiente
                    presente <= edo_read_adc_15_8;
                    -- entradas / salidas

                -- ****** FRAME 4: ADC DATA BYTE 1 ******
                when edo_read_adc_15_8 => -- data (8 bits: orden de recepción real="76543210", orden de recepción lógico="01234567")
                    if bits < 7 then
                        presente <= edo_read_adc_15_8;
                        bits <= bits + 1;
                    else
                        presente <= edo_ack_4;
                        bits <= 8;
                    end if;
                    -- entradas / salidas
                    mem_adc_16b(bits) <= i_read;
						  o_show_edo_frame <= 4;
                when edo_ack_4 => -- ESPERA: ack o _ack
                    -- edo. siguiente
                    presente <= edo_read_adc_7_0;
                    -- entradas / salidas
                    if bits = 7 then
                        o_ena <= '1';
                    end if;
                
                -- ****** FRAME 5: ADC DATA BYTE 0 ******
                when edo_read_adc_7_0 => -- data (8 bits: orden de recepción real="76543210", orden de recepción lógico="01234567")
                    if bits < 15 then
                        presente <= edo_read_adc_7_0;
                        bits <= bits + 1;
                    else
                        presente <= edo_ack_5;
                        bits <= 0;
                    end if;
                    -- entradas / salidas
                    mem_adc_16b(bits) <= i_read;
						  o_show_edo_frame <= 5;
                when edo_ack_5 => -- ESPERA: ack o _ack
                    -- edo. siguiente
                    presente <= edo_stop_f345;
                    -- entradas / salidas
                    if bits = 7 then
                        o_ena <= '0';
                    end if;

                when edo_stop_f345 =>
                    -- edo. siguiente
                    presente <= edo_start_f12;
                    -- entradas / salidas

                    
            end case;
        end if;
    end process;
end architecture;