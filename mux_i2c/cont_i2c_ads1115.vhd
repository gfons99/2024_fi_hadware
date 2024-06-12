-- ****************************************
-- tittle:	controlador genérico para i2c
-- author:	f.r., g.m.
-- date: 2024-04
-- description: máquina de estados de moore
-- ****************************************

library ieee;
use ieee.std_logic_1164.all;

entity cont_i2c_ads1115 is
    port (
        clk: in std_logic;
        ena: in std_logic;
        rst: in std_logic;

        io_scl: inout std_logic := '1';
        io_sda: inout std_logic := '1';
        
        debug_cont_pulso: out integer range 0 to 7;
        debug_cont_bits: out integer range 0 to 99;
        debug_cont_pos: out integer range 0 to 15;
        debug_cont_pos_8b: out integer range 0 to 7;

        debug_show_frame: out integer range 0 to 9;
        debug_mem_adc_16: out std_logic_vector(15 downto 0);
        debug_o_mem_bits: out std_logic_vector(7 downto 0)
    );
end entity;

architecture frgm of cont_i2c_ads1115 is 
    signal s_ack: std_logic := '0';

    signal s_cont_pulso: integer range 0 to 7 := 0; -- ancho del pulso = (50 mhz/2*fdeseada) - 1 = 7 --> de 000 a 111 = 8 = 3 bits    
    signal s_cont_bits: integer range 0 to 127 := 0;
    signal s_cont_pos: integer range 0 to 15 := 0;
    signal s_cont_pos_8b: integer range 0 to 7 := 0;

    -- datos:
    constant c_mem_dir_slave: std_logic_vector(6 downto 0) := "1001000"; -- dirección del esclavo
    constant c_mem_addr_p_reg_wr: std_logic_vector(7 downto 0) := "00000001"; -- config register [p1:p0]="01"
    constant c_mem_config_reg: std_logic_vector(15 downto 0) := "1100000010000011"; -- config register [p1:p0]="01"
    constant c_mem_addr_p_reg_rd: std_logic_vector(7 downto 0) := "00000000"; -- read from register [p1:p0]="00"

    signal s_mem_adc_16: std_logic_vector(15 downto 0) := "0000000000000000"; -- máx. 65,535, atorado en 65,278
    


begin
    process(clk,rst)

    begin
        if rst = '1' then
            io_scl <= '1';
            io_sda <= '1';

            s_cont_pulso <= 0;
            s_cont_bits <= 0;
            s_cont_pos <= 0;
            debug_show_frame <= 0;

            debug_o_mem_bits <= "00000000";
        
        elsif ena = '0' then
            -- no modificar nada

        elsif rising_edge(clk) then
            -- duración de 1 pulso
            if s_cont_pulso < 7 then
                s_cont_pulso <= s_cont_pulso + 1;
            else
                s_cont_pulso <= 0;
                s_cont_bits <= s_cont_bits + 1;
            end if;

            -- start
            if s_cont_bits = 0 or s_cont_bits = 38 or s_cont_bits = 58 then
                -- 0 1 2 3 4 5 6 7
                -- ⎺ ⎺ ⎺ ⎺ ⎺ ⎺ ⎽ ⎽ io_scl
                -- ⎺ ⎺ ⎺ ⎺ ⎽ ⎽ ⎽ ⎽ io_sda
                if s_cont_pulso = 0 then
                    io_scl <= '1';
                    io_sda <= '1';
                elsif s_cont_pulso = 4 then
                    io_sda <= '0';
                elsif s_cont_pulso = 6 then
                    io_scl <= '0';
                end if;
            -- stop
            elsif s_cont_bits = 37 or s_cont_bits = 57 or s_cont_bits = 86 then
                -- 0 1 2 3 4 5 6 7
                    -- ⎽ ⎽ ⎺ ⎺ ⎺ ⎺ ⎺ ⎺ io_scl
                    -- ⎽ ⎽ ⎽ ⎽ ⎺ ⎺ ⎺ ⎺ io_sda
                    if s_cont_pulso = 0 then
                        io_sda <= '0';
                    elsif s_cont_pulso = 2 then
                        io_scl <= '1';
                    elsif s_cont_pulso = 4 then
                        io_sda <= '1';
                    end if;
            -- pendiente: agregar elsifs start, stop
            else
                -- 0 1 2 3 4 5 6 7
                -- ⎽ ⎽ ⎺ ⎺ ⎺ ⎺ ⎽ ⎽ io_scl
                -- * * * * * * * * io_sda (low: ack, high: not ack)
                if s_cont_pulso = 0 then
                    io_scl <= '0';
                elsif s_cont_pulso = 2 then
                    io_scl <= '1';
                elsif s_cont_pulso = 5 then
                    io_scl <= '0';
                end if;
            end if;

            -- ************************
            -- Escritura / Configuración
            -- ************************
            -- wr, f1: slave address
            if s_cont_bits > 0 and s_cont_bits < 8 then
                io_sda <= c_mem_dir_slave(6 - s_cont_pos);
                if s_cont_pulso = 7 then
                    s_cont_pos <= s_cont_pos + 1;
                end if;

            -- wr, f1: r/_w = '0' write, r/_w = '1' read
            elsif s_cont_bits = 8 then
                io_sda <= '0';
                -- s_cont_pos <= s_cont_pos + 1;

            -- wr, f1: ack by ads1115
            elsif s_cont_bits = 9 then
                s_cont_pos <= 0;
                io_sda <= 'Z';

            -- wr, f2: address pointer register
            elsif s_cont_bits > 9 and s_cont_bits < 18 then
                -- wr, f1: ack by ads1115
                if s_cont_bits = 10 and s_cont_pulso = 4 then
                    s_ack <= io_sda;
                    -- pendiente: agregar qué pasa cuando no hay ack
                end if;
                io_sda <= c_mem_addr_p_reg_wr(7 - s_cont_pos);
                if s_cont_pulso = 7 then
                    s_cont_pos <= s_cont_pos + 1;
                end if;

            -- wr, f2: ack by ads1115
            elsif s_cont_bits = 18 then
                s_cont_pos <= 0;
                io_sda <= 'Z';
                
            -- wr, f3: config byte 1
            elsif s_cont_bits > 18 and s_cont_bits < 27 then
                -- wr, f2: ack by ads1115
                if s_cont_bits = 19 and s_cont_pulso = 4 then
                    s_ack <= io_sda;
                    -- pendiente: agregar qué pasa cuando no hay ack
                end if;
                io_sda <= c_mem_config_reg(15 - s_cont_pos);
                if s_cont_pulso = 7 then
                    s_cont_pos <= s_cont_pos + 1;
                end if;
            
            -- wr, f3: ack by ads1115
            elsif s_cont_bits = 27 then
                s_cont_pos <= 8;
                io_sda <= 'Z';

            -- wr, f4: config byte 0
            elsif s_cont_bits > 27 and s_cont_bits < 36 then
                -- wr, f3: ack by ads1115
                if s_cont_bits = 28 and s_cont_pulso = 4 then
                    s_ack <= io_sda;
                    -- pendiente: agregar qué pasa cuando no hay ack
                end if;
                io_sda <= c_mem_config_reg(15 - s_cont_pos);
                if s_cont_pulso = 7 then
                    s_cont_pos <= s_cont_pos + 1;
                end if;
            
            -- wr, f4: ack by ads1115
            elsif s_cont_bits = 36 then
                s_cont_pos <= 0;
                io_sda <= 'Z';
            
            -- wr, f4: stop
            elsif s_cont_bits = 37 then
                -- wr, f4: ack by ads1115
                if s_cont_bits = 37 and s_cont_pulso = 4 then
                    s_ack <= io_sda;
                    -- pendiente: agregar qué pasa cuando no hay ack
                end if;
            
            -- ************************
            -- Lectura / Conversión
            -- ************************
            -- rd, f1: slave address
            elsif s_cont_bits > 38 and s_cont_bits < 46 then
                io_sda <= c_mem_dir_slave(6 - s_cont_pos);
                if s_cont_pulso = 7 then
                    s_cont_pos <= s_cont_pos + 1;
                end if;

            -- rd, f1: r/_w = '0' write, r/_w = '1' read
            elsif s_cont_bits = 46 then
                io_sda <= '0';
                -- s_cont_pos <= s_cont_pos + 1;

            -- rd, f1: ack by ads1115
            elsif s_cont_bits = 47 then
                s_cont_pos <= 0;
                io_sda <= 'Z';

            -- rd, f2: address pointer register
            elsif s_cont_bits > 47 and s_cont_bits < 56 then
                -- rd, f1: ack by ads1115
                if s_cont_bits = 48 and s_cont_pulso = 4 then
                    s_ack <= io_sda;
                    -- pendiente: agregar qué pasa cuando no hay ack
                end if;
                io_sda <= c_mem_addr_p_reg_rd(7 - s_cont_pos);
                if s_cont_pulso = 7 then
                    s_cont_pos <= s_cont_pos + 1;
                end if;

            -- rd, f2: ack by ads1115
            elsif s_cont_bits = 56 then
                s_cont_pos <= 0;
                io_sda <= 'Z';
            
            -- rd, f2: stop
            elsif s_cont_bits = 57 then
                -- rd, f2: ack by ads1115
                if s_cont_bits = 57 and s_cont_pulso = 4 then
                    s_ack <= io_sda;
                    -- pendiente: agregar qué pasa cuando no hay ack
                end if;

            -- rd, f3: slave address
            elsif s_cont_bits > 58 and s_cont_bits < 66 then
                io_sda <= c_mem_dir_slave(6 - s_cont_pos);
                if s_cont_pulso = 7 then
                    s_cont_pos <= s_cont_pos + 1;
                end if;

            -- rd, f3: r/_w = '0' write, r/_w = '1' read
            elsif s_cont_bits = 66 then
                io_sda <= '1';
                -- s_cont_pos <= s_cont_pos + 1;

            -- rd, f3: ack by ads1115
            elsif s_cont_bits = 67 then
                s_cont_pos <= 0;
                io_sda <= 'Z';

            -- rd, f3: ack by ads1115
            elsif s_cont_bits = 68 and s_cont_pulso = 4 then
                    s_ack <= io_sda;
                    -- pendiente: agregar qué pasa cuando no hay ack

            -- rd, f4: data byte 1
            -- 69 70 71 72 73 74 75 76
            -- 0  1  2  3  4  5  6  7
            -- 15 14 13 12 11 10 9  8 
            elsif s_cont_bits > 68 and s_cont_bits < 77 then
                if s_cont_pulso = 4 then
                    s_mem_adc_16(15 - s_cont_pos) <= io_sda;
                    -- s_mem_adc_16(15 - s_cont_pos) <= '1';
                end if;
                if s_cont_pulso = 7 then
                    s_cont_pos <= s_cont_pos + 1;
                end if;

                -- rd, f4: ack by master
                if s_cont_pulso = 7 and s_cont_bits = 76 then
                    io_sda <= '0';
                end if;

            -- rd, f4: ack by master
            elsif s_cont_bits = 77 and s_cont_pulso = 4 then
                    s_ack <= io_sda;
                    -- pendiente: agregar qué pasa cuando no hay ack
                s_cont_pos <= 8;
                io_sda <= 'Z';

            -- rd, f5: data byte 0
            elsif s_cont_bits > 77 and s_cont_bits < 86 then
                if s_cont_pulso = 4 then
                    s_mem_adc_16(15 - s_cont_pos) <= io_sda;
                    -- s_mem_adc_16(15 - s_cont_pos) <= '1';
                end if;
                if s_cont_pulso = 7 then
                    s_cont_pos <= s_cont_pos + 1;
                end if;

                -- rd, f5: ack by master
                if s_cont_pulso = 7 and s_cont_bits = 85 then
                    io_sda <= '0';
                end if;
            
            -- rd, f5: ack by master  & stop
            elsif s_cont_bits = 86 then
                if s_cont_pulso = 4 then
                    s_ack <= io_sda;
                end if;
                -- pendiente: agregar qué pasa cuando no hay ack
                s_cont_pos <= 0;
                s_cont_bits <= 38;
                -- io_sda controlado por "stop"
            end if;

            -- ************************
            -- Debug de 8 bits
            -- ************************
            -- wr, f1: slave address
            if s_cont_bits > 1 and s_cont_bits < 10 then
                debug_show_frame <= 1;
                if s_cont_pulso = 4 then
                    debug_o_mem_bits(s_cont_pos_8b) <= io_sda;
                end if;
                if s_cont_pulso = 7 then
                    s_cont_pos_8b <= s_cont_pos_8b + 1;
                end if;
            elsif s_cont_bits = 10 then
                s_cont_pos_8b <= 0;
                debug_o_mem_bits <= "00000000";
            elsif s_cont_bits > 10 and s_cont_bits < 19 then
                debug_show_frame <= 2;
                if s_cont_pulso = 4 then
                    debug_o_mem_bits(s_cont_pos_8b) <= io_sda;
                end if;
                if s_cont_pulso = 7 then
                    s_cont_pos_8b <= s_cont_pos_8b + 1;
                end if;
            elsif s_cont_bits = 19 then
                s_cont_pos_8b <= 0;
                debug_o_mem_bits <= "00000000";
            elsif s_cont_bits > 19 and s_cont_bits < 28 then
                debug_show_frame <= 3;
                if s_cont_pulso = 4 then
                    debug_o_mem_bits(s_cont_pos_8b) <= io_sda;
                end if;
                if s_cont_pulso = 7 then
                    s_cont_pos_8b <= s_cont_pos_8b + 1;
                end if;
            elsif s_cont_bits = 28 then
                s_cont_pos_8b <= 0;
                debug_o_mem_bits <= "00000000";
            elsif s_cont_bits > 28 and s_cont_bits < 37 then
                debug_show_frame <= 4;
                if s_cont_pulso = 4 then
                    debug_o_mem_bits(s_cont_pos_8b) <= io_sda;
                end if;
                if s_cont_pulso = 7 then
                    s_cont_pos_8b <= s_cont_pos_8b + 1;
                end if;
            elsif s_cont_bits = 37 then
                s_cont_pos_8b <= 0;
                debug_o_mem_bits <= "00000000";
            elsif s_cont_bits > 39 and s_cont_bits < 48 then
                debug_show_frame <= 5;
                if s_cont_pulso = 4 then
                    debug_o_mem_bits(s_cont_pos_8b) <= io_sda;
                end if;
                if s_cont_pulso = 7 then
                    s_cont_pos_8b <= s_cont_pos_8b + 1;
                end if;
            elsif s_cont_bits = 48 then
                s_cont_pos_8b <= 0;
                debug_o_mem_bits <= "00000000";
            elsif s_cont_bits > 48 and s_cont_bits < 57 then
                debug_show_frame <= 6;
                if s_cont_pulso = 4 then
                    debug_o_mem_bits(s_cont_pos_8b) <= io_sda;
                end if;
                if s_cont_pulso = 7 then
                    s_cont_pos_8b <= s_cont_pos_8b + 1;
                end if;
            elsif s_cont_bits = 57 then
                s_cont_pos_8b <= 0;
                debug_o_mem_bits <= "00000000";
            elsif s_cont_bits > 59 and s_cont_bits < 68 then
                debug_show_frame <= 7;
                if s_cont_pulso = 4 then
                    debug_o_mem_bits(s_cont_pos_8b) <= io_sda;
                end if;
                if s_cont_pulso = 7 then
                    s_cont_pos_8b <= s_cont_pos_8b + 1;
                end if;
            elsif s_cont_bits = 68 then
                s_cont_pos_8b <= 0;
                debug_o_mem_bits <= "00000000";
            -- 69 70 71 72 73 74 75 76
            -- 0  1  2  3  4  5  6  7
            -- 15 14 13 12 11 10 9  8
            -- 1  0  1  1  1  1  1  0
            elsif s_cont_bits > 68 and s_cont_bits < 77 then
                debug_show_frame <= 8;
                if s_cont_pulso = 4 then
                    debug_o_mem_bits(s_cont_pos_8b) <= io_sda;
                end if;
                if s_cont_pulso = 7 then
                    s_cont_pos_8b <= s_cont_pos_8b + 1;
                end if;
            elsif s_cont_bits = 77 then
                s_cont_pos_8b <= 0;
                debug_o_mem_bits <= "00000000";
            elsif s_cont_bits > 77 and s_cont_bits < 86 then
                debug_show_frame <= 9;
                if s_cont_pulso = 4 then
                    debug_o_mem_bits(s_cont_pos_8b) <= io_sda;
                end if;
                if s_cont_pulso = 7 then
                    s_cont_pos_8b <= s_cont_pos_8b + 1;
                end if;
            elsif s_cont_bits = 86 then
                s_cont_pos_8b <= 0;
                debug_o_mem_bits <= "00000000";
            end if;

        end if;
    end process;

    debug_cont_pulso <= s_cont_pulso;
    debug_cont_bits <= s_cont_bits;
    debug_cont_pos <= s_cont_pos;
    debug_cont_pos_8b <= s_cont_pos_8b;
    debug_mem_adc_16 <= s_mem_adc_16;
end architecture;