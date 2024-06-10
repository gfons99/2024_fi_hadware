-- ****************************************
-- tittle:    controlador para el ads1115
-- author:    f.r., g.m.
-- date: 2024-04
-- description: máquina de estados de moore
-- ****************************************

library ieee;
use ieee.std_logic_1164.all;

entity i2c_ads1115_fsm is
    port (
        -- entradas:
        clk: in std_logic;
        rst: in std_logic;
        ena: out std_logic;

        i_rx: in std_logic;
        o_tx: out std_logic;
        
        sw_adc_ch: in std_logic_vector(1 downto 0);

        -- salidas:
        debug_o_show_edo: buffer integer range 0 to 9;
        debug_o_show_pulso: out integer range 0 to 9;
        debug_o_show_cont_bits: out integer range 0 to 15;
        adc_16b: out std_logic_vector(15 downto 0)
    );
end entity;

architecture frgm of i2c_ads1115_fsm is 
    type estados is(
        -- escritura / configuración
        edo_wr_f1_iddle,
        edo_wr_f1_start,
        edo_wr_f1_dir_slv,
        edo_wr_f1_ack1,

        edo_wr_f2_addr_p_reg,
        edo_wr_f2_ack2,

        edo_wr_f3_config_15_8,
        edo_wr_f3_ack3,
        
        edo_wr_f4_config_7_0,
        edo_wr_f4_ack4,
        edo_wr_f4_stop,
        
        -- -- lectura
        -- edo_rd_f5_iddle,
        -- edo_rd_f5_start_f12,
        -- edo_rd_f5_dir_slv_f12,
        -- edo_rd_f5_ack1,
        
        -- edo_rd_f6_addr_p_reg,
        -- edo_rd_f6_ack2,
        -- edo_rd_f6_stop_f12,

        -- edo_rd_f7_iddle_f345,
        -- edo_rd_f7_start_f345,
        -- edo_rd_f7_dir_slv_f345,
        -- edo_rd_f7_ack3,
        
        -- edo_rd_f8_adc_15_8,
        -- edo_rd_f8_ack_4,
        
        -- edo_rd_f9_adc_7_0,
        -- edo_rd_f9_ack_5,
        -- edo_rd_f9_stop_f345,

        edo_error
        );
    signal presente: estados := edo_wr_f1_iddle;

    signal s_cont_pulso: integer range 0 to 7 := 0; -- ancho del pulso = (50 mhz/2*fdeseada) - 1 = 7 --> de 000 a 111 = 8 = 3 bits    
    signal s_cont_bits: integer range 0 to 15 := 0;

    signal s_rw: std_logic := '0';
    signal s_ack: std_logic := '0';

    signal s_ruta: integer range 0 to 3 := 0;
    -- 0 wr f1, wr f2
    -- 1 rd f1, rd f2
    -- 2 rd f3, rd f4, rd f5
    -- 3

    constant c_pulso_0_7: integer := 7;
    constant c_bits_7: integer := 7;

    -- signal mem_rd_adc: std_logic_vector(15 downto 0);

    -- datos:
    -- constant mem_dir_slave: std_logic_vector(6 downto 0) := "1010101"; -- dirección del esclavo
    constant mem_dir_slave: std_logic_vector(6 downto 0) := "1001000"; -- dirección del esclavo
    constant mem_addr_p_reg_rd: std_logic_vector(7 downto 0) := "00000000"; -- read from register [p1:p0]="00"
    constant mem_addr_p_reg_wr: std_logic_vector(7 downto 0) := "00000001"; -- config register [p1:p0]="01"
    constant mem_config_reg: std_logic_vector(15 downto 0) := "1100000110000011"; -- config register [p1:p0]="01"

begin
    process(clk,rst)
    begin
        if rst = '1' then
            debug_o_show_edo <= 0;
            s_cont_pulso <= 0;
            s_cont_bits <= 0;
            s_rw <= '0';
            s_ack <= '0';

            presente <= edo_wr_f1_iddle;
        elsif rising_edge(clk) then
            case presente is
                -- escritura / configuración
                -- ****** frame 1: slave receiver address & rw ******
                when edo_wr_f1_iddle =>
                    debug_o_show_edo <= 0;
                    if s_cont_pulso < 7 then
                        s_cont_pulso <= s_cont_pulso + 1;
                        presente <= edo_wr_f1_iddle;
                        -- entradas / salidas
                        ena <= '1';
                    else
                        s_cont_pulso <= 0;
                        presente <= edo_wr_f1_start;
                        -- debug_o_show_edo <= debug_o_show_edo + 1;
                        -- entradas / salidas
                        ena <= '0';
                    end if;

                when edo_wr_f1_start =>
                    debug_o_show_edo <= 1;
                    if s_cont_pulso < 6 then
                        s_cont_pulso <= s_cont_pulso + 1;
                        presente <= edo_wr_f1_start;
                        -- entradas / salidas
                    else
                        s_cont_pulso <= 0;
                            presente <= edo_wr_f1_dir_slv;
                        -- debug_o_show_edo <= debug_o_show_edo + 1;
                        -- entradas / salidas
                    end if;

                when edo_wr_f1_dir_slv => -- slave receiver address (8 bits: orden de envío real="6543210 & rw", orden de envío lógico="0123456  & rw")
                    debug_o_show_edo <= 2;
                    if s_cont_pulso < 7 then
                        s_cont_pulso <= s_cont_pulso + 1;
                        presente <= edo_wr_f1_dir_slv;
                    else
                        s_cont_pulso <= 0;
                        if s_cont_bits < 7 then
                            s_cont_bits <= s_cont_bits + 1;
                            presente <= edo_wr_f1_dir_slv;
                        else
                            s_cont_bits <= 0;
                            presente <= edo_wr_f1_ack1;
                            -- debug_o_show_edo <= debug_o_show_edo + 1;
                        end if;
                    end if;
                    -- entradas / salidas
                    if s_cont_bits < 7 then
                        o_tx <= mem_dir_slave(6 - s_cont_bits);
                    else
                        o_tx <= '0'; -- (r/_w): '1' read, '0' write
                    end if;

                when edo_wr_f1_ack1 => -- espera: ack o _ack
                    debug_o_show_edo <= 3;
                    if s_cont_pulso < 7 then
                        s_cont_pulso <= s_cont_pulso + 1;
                        presente <= edo_wr_f1_ack1;
                        -- entradas / salidas
                        if s_cont_pulso = 6 then
                            s_ack <= i_rx;
                        end if;
                    else
                        s_cont_pulso <= 0;
                        if s_ack = '0' then
                            presente <= edo_wr_f2_addr_p_reg;
                            -- debug_o_show_edo <= debug_o_show_edo + 1;
                        else  -- s_ack = '1' then
                            presente <= edo_error;
                            -- pendiente: agregar debug_o_show_edo
                        end if;
                        -- entradas / salidas
                    end if;  
                
                -- -- ****** frame 2: address pointer register ******
                when edo_wr_f2_addr_p_reg => -- data (8 bits: orden de envío real="76543210", orden de envío lógico="01234567")
                    debug_o_show_edo <= 4;
                    if s_cont_pulso < 7 then
                        s_cont_pulso <= s_cont_pulso + 1;
                        presente <= edo_wr_f2_addr_p_reg;
                    else
                        s_cont_pulso <= 0;
                        if s_cont_bits < 7 then
                            s_cont_bits <= s_cont_bits + 1;
                            presente <= edo_wr_f2_addr_p_reg;
                        else
                            s_cont_bits <= 0;
                            presente <= edo_wr_f2_ack2;
                            -- debug_o_show_edo <= debug_o_show_edo + 1;
                        end if;
                    end if;
                    -- entradas / salidas
                    o_tx <= mem_addr_p_reg_wr(7 - s_cont_bits);
                
                when edo_wr_f2_ack2 => -- espera: ack o _ack
                    debug_o_show_edo <= 5;
                    if s_cont_pulso < 7 then
                        s_cont_pulso <= s_cont_pulso + 1;
                        presente <= edo_wr_f2_ack2;
                        -- entradas / salidas
                        if s_cont_pulso = 6 then
                            s_ack <= i_rx;
                        end if;
                    else
                        s_cont_pulso <= 0;
                        if s_ack = '0' then
                            presente <= edo_wr_f3_config_15_8;
                            -- debug_o_show_edo <= debug_o_show_edo + 1;
                        else  -- s_ack = '1' then
                            presente <= edo_error;
                            -- pendiente: agregar debug_o_show_edo
                        end if;
                        -- entradas / salidas
                    end if;
                    -- entradas / salidas
                    ena <= '1';

                -- ****** frame 3: config byte 1 ******
                when edo_wr_f3_config_15_8 => -- data (8 bits: orden de recepción real="76543210", orden de recepción lógico="01234567")
                    debug_o_show_edo <= 6;
                    if s_cont_pulso < 7 then
                        s_cont_pulso <= s_cont_pulso + 1;
                        presente <= edo_wr_f3_config_15_8;
                    else
                        s_cont_pulso <= 0;
                        if s_cont_bits < 7 then
                            s_cont_bits <= s_cont_bits + 1;
                            presente <= edo_wr_f3_config_15_8;
                        else
                            s_cont_bits <= 8;
                            presente <= edo_wr_f3_ack3;
                            -- debug_o_show_edo <= debug_o_show_edo + 1;
                        end if;
                    end if;
                    -- entradas / salidas
                    o_tx <= mem_config_reg(15 - s_cont_bits);
                    ena <= '0';

                when edo_wr_f3_ack3 => -- espera: ack o _ack
                    debug_o_show_edo <= 7;
                    if s_cont_pulso < 7 then
                        s_cont_pulso <= s_cont_pulso + 1;
                        presente <= edo_wr_f3_ack3;
                        -- entradas / salidas
                        if s_cont_pulso = 6 then
                            s_ack <= i_rx;
                        end if;
                    else
                        s_cont_pulso <= 0;
                        if s_ack = '0' then
                            presente <= edo_wr_f4_config_7_0;
                            -- debug_o_show_edo <= debug_o_show_edo + 1;
                        else  -- s_ack = '1' then
                            presente <= edo_error;
                            -- pendiente: agregar debug_o_show_edo
                        end if;
                        -- entradas / salidas
                    end if;
                    -- entradas / salidas
                    ena <= '1';
                    
                -- ****** frame 4: config byte 0 ******
                when edo_wr_f4_config_7_0 => -- data (8 bits: orden de recepción real="76543210", orden de recepción lógico="01234567")
                    debug_o_show_edo <= 8;
                    if s_cont_pulso < 7 then
                        s_cont_pulso <= s_cont_pulso + 1;
                        presente <= edo_wr_f4_config_7_0;
                    else
                        s_cont_pulso <= 0;
                        if s_cont_bits < 15 then
                            s_cont_bits <= s_cont_bits + 1;
                            presente <= edo_wr_f4_config_7_0;
                        else
                            s_cont_bits <= 0;
                            presente <= edo_wr_f4_ack4;
                            -- debug_o_show_edo <= debug_o_show_edo + 1;
                        end if;
                    end if;
                    -- entradas / salidas
                    o_tx <= mem_config_reg(15 - s_cont_bits);
                    ena <= '0';
                
                when edo_wr_f4_ack4 => -- espera: ack o _ack
                    debug_o_show_edo <= 9;
                    if s_cont_pulso < 7 then
                        s_cont_pulso <= s_cont_pulso + 1;
                        presente <= edo_wr_f4_ack4;
                        -- entradas / salidas
                        if s_cont_pulso = 6 then
                            s_ack <= i_rx;
                        end if;
                    else
                        s_cont_pulso <= 0;
                        if s_ack = '0' then
                            presente <= edo_wr_f4_stop;
                            -- debug_o_show_edo <= debug_o_show_edo + 1;
                        else  -- s_ack = '1' then
                            presente <= edo_error;
                            -- pendiente: agregar debug_o_show_edo
                        end if;
                        -- entradas / salidas
                    end if;
                    -- entradas / salidas
                    ena <= '0';

                when edo_wr_f4_stop =>
                    -- debug_o_show_edo <= 10;
                    if s_cont_pulso < 8 then
                        presente <= edo_wr_f4_stop;
                    -- else
                    --     presente <= edo_idle;
                    --     debug_o_show_edo <= 0;
                    end if;
                    -- entradas / salidas

                -- -- lectura
                -- -- ****** frame 1: slave receiver address & rw ******
                -- when edo_rd_iddle =>
                --     -- edo. siguiente
                --     presente <= edo_rd_start_f12;
                --     -- entradas / salidas
                --     o_ena <= '1';
                --     -- debug_o_show_edo <= debug_o_show_edo + 1;
                -- when edo_rd_start_f12 =>
                --     -- edo. siguiente
                --     presente <= edo_rd_dir_slv_f12;
                --     -- entradas / salidas
                -- when edo_rd_dir_slv_f12 => -- slave receiver address (8 bits: orden de envío real="6543210 & rw", orden de envío lógico="0123456  & rw")
                --     -- edo. siguiente
                --     if bits < 7 then
                --         presente <= edo_rd_dir_slv_f12;
                --         bits <= bits + 1;
                --     else
                --         presente <= edo_rd_ack1;
                --         bits <= 0;
                --     end if;
                --     -- entradas / salidas
                --     if bits = 7 then
                --         o_write <= '0'; -- (r/_w): '1' read, '0' write
                --     else
                --         o_write <= mem_dir_slave(bits);
                --     end if;
                -- when edo_rd_ack1 => -- espera: ack o _ack
                --     -- edo. siguiente
                --     presente <= edo_rd_addr_p_reg;
                --     -- entradas / salidas
                
                -- -- ****** frame 2: address pointer register ******
                -- when edo_rd_addr_p_reg => -- data (8 bits: orden de envío real="76543210", orden de envío lógico="01234567")
                --     if bits < 7 then
                --         presente <= edo_rd_addr_p_reg;
                --         bits <= bits + 1;
                --     else
                --         presente <= edo_rd_ack2;
                --         bits <= 0;
                --     end if;
                --     -- entradas / salidas
                --     o_write <= mem_addr_p_reg_rd(bits);
                --     -- debug_o_show_edo <= debug_o_show_edo + 1;
                -- when edo_rd_ack2 => -- espera: ack o _ack
                --     -- edo. siguiente
                --     presente <= edo_rd_stop_f12;
                --     -- entradas / salidas
                --     o_ena <= '0';
                -- when edo_rd_stop_f12 =>
                --     -- edo. siguiente
                --     presente <= edo_rd_iddle_f345;
                --     -- entradas / salidas
                
                -- -- ****** frame 3: slave receiver address & rw ******
                -- when edo_rd_iddle_f345 =>
                --     -- edo. siguiente
                --     presente <= edo_rd_start_f345;
                --     -- entradas / salidas
                --     o_ena <= '1';
                --     debug_o_show_edo <= 3;
                -- when edo_rd_start_f345 =>
                --     -- edo. siguiente
                --     presente <= edo_rd_dir_slv_f345;
                --     -- entradas / salidas
                -- when edo_rd_dir_slv_f345 => -- slave receiver address (8 bits: orden de envío real="6543210 & rw", orden de envío lógico="0123456  & rw")
                --     -- edo. siguiente
                --     if bits < 7 then
                --         presente <= edo_rd_dir_slv_f345;
                --         bits <= bits + 1;
                --     else
                --         presente <= edo_rd_ack3;
                --         bits <= 0;
                --     end if;
                --     -- entradas / salidas
                --     if bits = 7 then
                --         o_write <= '1'; -- (r/_w): '1' read, '0' write
                --     else
                --         o_write <= mem_dir_slave(bits);
                --     end if;
                -- when edo_rd_ack3 => -- espera: ack o _ack
                --     -- edo. siguiente
                --     presente <= edo_rd_adc_15_8;
                --     -- entradas / salidas

                -- -- ****** frame 4: adc data byte 1 ******
                -- when edo_rd_adc_15_8 => -- data (8 bits: orden de recepción real="76543210", orden de recepción lógico="01234567")
                --     if bits < 7 then
                --         presente <= edo_rd_adc_15_8;
                --         bits <= bits + 1;
                --     else
                --         presente <= edo_rd_ack_4;
                --         bits <= 8;
                --     end if;
                --     -- entradas / salidas
                --     adc_16b(bits) <= i_read;
                --     -- debug_o_show_edo <= debug_o_show_edo + 1;
                -- when edo_rd_ack_4 => -- espera: ack o _ack
                --     -- edo. siguiente
                --     presente <= edo_rd_adc_7_0;
                --     -- entradas / salidas
                    
                -- -- ****** frame 5: adc data byte 0 ******
                -- when edo_rd_adc_7_0 => -- data (8 bits: orden de recepción real="76543210", orden de recepción lógico="01234567")
                --     if bits < 15 then
                --         presente <= edo_rd_adc_7_0;
                --         bits <= bits + 1;
                --     else
                --         presente <= edo_rd_ack_5;
                --         bits <= 0;
                --     end if;
                --     -- entradas / salidas
                --     adc_16b(bits) <= i_read;
                --     -- debug_o_show_edo <= debug_o_show_edo + 1;
                -- when edo_rd_ack_5 => -- espera: ack o _ack
                --     -- edo. siguiente
                --     presente <= edo_rd_stop_f345;
                --     -- entradas / salidas
                --     o_ena <= '0';
                -- when edo_rd_stop_f345 =>
                -- -- edo. siguiente
                --     presente <= edo_wr_f1_iddle;
                --     -- entradas / salidas

                when edo_error =>
                    -- edo. siguiente
                    if s_cont_pulso < c_pulso_0_7 then
                        presente <= edo_error;
                    else
                        presente <= edo_error;
                    end if;
                end case;
        end if;
        debug_o_show_pulso <= s_cont_pulso;
        debug_o_show_cont_bits <= s_cont_bits;
    end process;
end architecture;