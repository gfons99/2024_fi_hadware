-- ****************************************
-- tittle:	controlador genérico para i2c
-- author:	f.r., g.m.
-- date: 2024-04
-- description: máquina de estados de moore
-- ****************************************

library ieee;
use ieee.std_logic_1164.all;

entity i2c_general_fsm is
    port (
        -- entradas:
        clk_50: in std_logic;
        rst: in std_logic;
        ena: in std_logic;

        io_scl: inout std_logic := '1';
        io_sda: inout std_logic := '1';
        
        i_rx: in std_logic;
        o_tx: out std_logic;

        o_error: out std_logic;
        debug_o_show_edo: buffer integer range 0 to 9;
        debug_o_show_pulso: out integer range 0 to 9;
        debug_o_show_cont_bits: out integer range 0 to 7;
        debug_o_mem_bits: out std_logic_vector(7 downto 0)
    );
end entity;

architecture frgm of i2c_general_fsm is 
    type estados is(
        edo_idle,
        edo_start,
        edo_frame1,
        edo_ack1,
        edo_write,
        edo_ack2_write,
        edo_read,
        edo_ack2_read,
        edo_stop,
        edo_error
    );
    signal presente: estados := edo_idle;

    signal s_rw: std_logic := '0';
    signal s_ack: std_logic := '0';

    signal s_cont_pulso: integer range 0 to 7 := 0; -- ancho del pulso = (50 mhz/2*fdeseada) - 1 = 7 --> de 000 a 111 = 8 = 3 bits    
    signal s_cont_bits: integer range 0 to 7 := 0;
    
    constant c_pulso_0_7: integer := 7;
    constant c_bits_7: integer := 7;

begin
    process(clk_50,rst,ena)
    begin
        if rst = '1' then
            debug_o_show_edo <= 0;
            s_cont_pulso <= 0;
            s_cont_bits <= 0;

            debug_o_mem_bits <= "00000000";
            presente <= edo_idle;
        elsif rising_edge(clk_50) then
            -- duración de 1 estado
            if s_cont_pulso < c_pulso_0_7 then
                s_cont_pulso <= s_cont_pulso + 1;
            else
                s_cont_pulso <= 0;
            end if;

            case presente is
                when edo_idle =>
                    -- 0 1 2 3 4 5 6 7
                    -- ⎺ ⎺ ⎺ ⎺ ⎺ ⎺ ⎺ ⎺ io_scl
                    -- ⎺ ⎺ ⎺ ⎺ ⎺ ⎺ ⎺ ⎺ io_sda
                    io_scl <= '1';
                    io_sda <= '1';
                    -- edo. siguiente
                    if s_cont_pulso < c_pulso_0_7 then
                        presente <= edo_idle;
                    else
                        if ena = '1' then
                            presente <= edo_start;
                            debug_o_show_edo <= 1;
                        else
                            presente <= edo_idle;
                        end if;
                    end if;
                
                when edo_start =>
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
                    -- edo. siguiente
                    if s_cont_pulso < c_pulso_0_7 then
                        presente <= edo_start;
                    else
                        presente <= edo_frame1;
                        debug_o_show_edo <= 2;
                    end if;

                -- ****** frame 1: slave receiver address & rw ******
                -- (8 bits: orden de envío real="6543210 & rw", orden de envío lógico="0123456  & rw")
                
                -- 7 0 1 2 3 4 5 6 7 0 -- inputs / outputs
                --   * * * * * * * *   -- rx
                --   i i i i i i i i   -- edo_frame1
                --     o o o o o o o o -- sda
                when edo_frame1 =>
                    -- 0 1 2 3 4 5 6 7
                    -- ⎽ ⎽ ⎺ ⎺ ⎺ ⎺ ⎽ ⎽ io_scl
                    -- * * * * * * * * io_sda
                    if s_cont_pulso = 0 then
                        io_scl <= '0';
                    elsif s_cont_pulso = 2 then
                        io_scl <= '1';
                    elsif s_cont_pulso = 6 then
                        io_scl <= '0'; 
                    end if;
                    -- edo. siguiente
                    if s_cont_pulso < c_pulso_0_7 then
                        presente <= edo_frame1;
                    else
                        if s_cont_bits < 7 then
                            s_cont_bits <= s_cont_bits + 1;
                            presente <= edo_frame1;
                        else
                            s_cont_bits <= 0;
                            presente <= edo_ack1;
                            debug_o_show_edo <= 3;
                        end if;
                        -- entradas / salidas
                        s_rw <= i_rx; -- r/_w
                    end if;
                    -- entradas / salidas
                    io_sda <= i_rx;
                    debug_o_mem_bits(s_cont_bits) <= i_rx;
                
                when edo_ack1 =>
                    -- 0 1 2 3 4 5 6 7
                    -- ⎽ ⎽ ⎺ ⎺ ⎺ ⎺ ⎽ ⎽ io_scl
                    -- . . . . * . . . io_sda (low: ack, high: not ack)
                    if s_cont_pulso = 0 then
                        io_scl <= '0';
                    elsif s_cont_pulso = 2 then
                        io_scl <= '1';
                    elsif s_cont_pulso = 6 then
                        io_scl <= '0';
                    end if;
                    -- edo. siguiente
                    if s_cont_pulso < c_pulso_0_7 then
                        presente <= edo_ack1;
                        -- entradas / salidas
                        if s_cont_pulso = 4 then
                            s_ack <= io_sda;
                            o_tx <= io_sda;
                        end if;
                    else
                        if s_ack = '0' then
                            if s_rw = '0' then
                                presente <= edo_write;
                                debug_o_show_edo <= 4;
                            elsif s_rw = '1' then
                                presente <= edo_read;
                                debug_o_show_edo <= 6;
                            end if;
                        else -- s_ack = '1' then
                            presente <= edo_error;
                            debug_o_show_edo <= 9;
                        end if;
                    end if;
                    -- entradas / salidas
                    io_sda <= 'Z';
                    debug_o_mem_bits <= "00000000";

                -- ****** frame 2: write data ******
                -- data (8 bits: orden de envío real="76543210", orden de envío lógico="01234567")
                when edo_write =>
                    -- 0 1 2 3 4 5 6 7
                    -- ⎽ ⎽ ⎺ ⎺ ⎺ ⎺ ⎽ ⎽ io_scl
                    -- * * * * * * * * io_sda
                    if s_cont_pulso = 0 then
                        io_scl <= '0';
                    elsif s_cont_pulso = 2 then
                        io_scl <= '1';
                    elsif s_cont_pulso = 6 then
                        io_scl <= '0';
                    end if;
                    -- edo. siguiente
                    if s_cont_pulso < c_pulso_0_7 then
                        presente <= edo_write;
                    else
                        if s_cont_bits < 7 then
                            s_cont_bits <= s_cont_bits + 1;
                            presente <= edo_write;
                        else
                            s_cont_bits <= 0;
                            presente <= edo_ack2_write;
                            debug_o_show_edo <= 5;
                        end if;
                    end if;
                    -- entradas / salidas
                    io_sda <= i_rx;
                    debug_o_mem_bits(s_cont_bits) <= i_rx;

                when edo_ack2_write =>
                    -- 0 1 2 3 4 5 6 7
                    -- ⎽ ⎽ ⎺ ⎺ ⎺ ⎺ ⎽ ⎽ io_scl
                    -- * * * * * * * * io_sda (low: ack, high: not ack)
                    if s_cont_pulso = 0 then
                        io_scl <= '0';
                    elsif s_cont_pulso = 2 then
                        io_scl <= '1';
                    elsif s_cont_pulso = 6 then
                        io_scl <= '0';
                    end if;
                    -- edo. siguiente
                    if s_cont_pulso < c_pulso_0_7 then
                        presente <= edo_ack2_write;
                        -- entradas / salidas
                        if s_cont_pulso = 4 then
                            s_ack <= io_sda;
                            o_tx <= io_sda;
                        end if;
                    else
                        if s_ack = '0' and ena = '1' then
                            presente <= edo_write;
                            debug_o_show_edo <= 4;
                        elsif s_ack = '0' and ena = '0' then
                            presente <= edo_stop;
                            debug_o_show_edo <= 8;
                        else -- s_ack = '1'
                            presente <= edo_error;
                            debug_o_show_edo <= 9;
                        end if;
                    end if;
                    -- entradas / salidas
                    io_sda <= 'Z';
                    debug_o_mem_bits <= "00000000";
                
                -- ****** frame 2: read data ******
                -- data (8 bits: orden de recepción real="76543210", orden de recepción lógico="01234567")
                when edo_read =>
                    -- 0 1 2 3 4 5 6 7
                    -- ⎽ ⎽ ⎺ ⎺ ⎺ ⎺ ⎽ ⎽ io_scl
                    -- * * * * * * * * io_sda
                    if s_cont_pulso = 0 then
                        io_scl <= '0';
                        o_tx <= io_sda;
                    elsif s_cont_pulso = 2 then
                        io_scl <= '1';
                    elsif s_cont_pulso = 6 then
                        io_scl <= '0';
                    end if;
                    -- edo. siguiente
                    if s_cont_pulso < c_pulso_0_7 then
                        presente <= edo_read;
                    else
                        if s_cont_bits < 7 then
                            s_cont_bits <= s_cont_bits + 1;
                            presente <= edo_read;
                        else
                            s_cont_bits <= 0;
                            presente <= edo_ack2_read;
                            debug_o_show_edo <= 7;
                            io_sda <= 'Z';
                        end if;
                    end if;

                when edo_ack2_read =>
                    -- 0 1 2 3 4 5 6 7
                    -- ⎽ ⎽ ⎺ ⎺ ⎺ ⎺ ⎽ ⎽ io_scl
                    -- * * * * * * * * io_sda (low: ack, high: not ack)
                    if s_cont_pulso = 0 then
                        io_scl <= '0';
                        s_ack <= i_rx;
                    elsif s_cont_pulso = 2 then
                        io_scl <= '1';
                    elsif s_cont_pulso = 6 then
                        io_scl <= '0';
                    end if;
                    -- edo. siguiente
                    if s_cont_pulso < c_pulso_0_7 then
                        presente <= edo_ack2_read;
                    else
                        if s_ack = '0' and ena = '1' then
                            presente <= edo_read;
                            debug_o_show_edo <= 6;
                            io_sda <= 'Z';
                        elsif s_ack = '0' and ena = '0' then
                            presente <= edo_stop;
                            debug_o_show_edo <= 8;
                        else -- s_ack = '1'
                            presente <= edo_error;
                            debug_o_show_edo <= 9;
                        end if;
                    end if;
                    -- entradas / salidas
                    debug_o_mem_bits <= "00000000";
                
                -- ****** fin de i2c ******
                when edo_stop =>
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
                    -- edo. siguiente
                    if s_cont_pulso < c_pulso_0_7 then
                        presente <= edo_stop;
                    else
                        presente <= edo_idle;
                        debug_o_show_edo <= 0;
                    end if;
                when edo_error =>
                    -- 0 1 2 3 4 5 6 7
                    -- ⎽ ⎽ ⎺ ⎺ ⎺ ⎺ ⎽ ⎽ io_scl
                    -- * * * * * * * * io_sda (low: ack, high: not ack)
                    io_scl <= '1';
                    io_sda <= '1';
                    o_error <= '1';
                    -- edo. siguiente
                    if s_cont_pulso < c_pulso_0_7 then
                        presente <= edo_error;
                    else
                        presente <= edo_error;
                    end if;
            end case;
        end if;
    end process;

    debug_o_show_pulso <= s_cont_pulso;
    debug_o_show_cont_bits <= s_cont_bits;
end architecture;