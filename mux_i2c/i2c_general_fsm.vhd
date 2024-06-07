-- ****************************************
-- tittle:	Controlador genérico para I2C
-- author:	F.R., G.M.
-- date: 2024-04
-- description: Máquina de estados de Moore
-- ****************************************

library ieee;
use ieee.std_logic_1164.all;

entity i2c_general_fsm is
    port (
        -- entradas:
        clk_50: in std_logic;
        rst, ena: in std_logic;

        -- i_write: in std_logic;
        -- i_sda: in std_logic;
        -- salidas:
        -- sel_scl: out std_logic_vector(1 downto 0) := "01"; -- 00: io_scl    -- 01: '1'
        -- sel_sda: out std_logic_vector(1 downto 0) := "01"; -- 00: dcl    -- 01: '1' o -- 10: datos -- 11: not dcl

        -- o_read:out std_logic;
        io_scl: inout std_logic := '1';
        io_sda: inout std_logic := '1';
        io_com: inout std_logic := 'Z';

        o_error: out std_logic
    );
end entity;

architecture frgm of i2c_general_fsm is 
    type estados is(edo_idle,edo_start,edo_frame1,edo_ack1,edo_write,edo_ack2_write,edo_read,edo_ack2_read,edo_stop);
    signal presente: estados := edo_idle;

    signal s_cont_pulso: integer range 0 to 7 := 0; -- ancho del pulso = (50 mhz/2*fdeseada) - 1 = 7 --> de 000 a 111 = 8 = 3 bits    
    signal bits: integer range 0 to 7 := 0;

    signal s_rw: std_logic := 'Z';
    signal s_ack: std_logic := 'Z';

    constant c_pulso_0_7: integer := 7;
    constant c_bits_7: integer := 7;

begin
    process(clk_50,rst,ena)
    begin
        if rst = '1' then
            presente <= edo_idle;
        elsif rising_edge(clk_50) then

            case presente is
                when edo_idle =>
                    -- 0
                    -- ⎺ io_scl
                    -- ⎺ io_sda
                    io_scl <= '1';
                    io_sda <= '1';
                    -- duración de 1 estado:
                    if ena = '0' then
                        presente <= edo_idle;
                    else
                        presente <= edo_start;
                    end if;
                
                when edo_start =>
                    -- 0 1 2 3 4 5 6 7
                    -- ⎺ ⎺ ⎺ ⎺ ⎺ ⎺ ⎽ ⎽ io_scl
                    -- ⎺ ⎺ ⎺ ⎺ ⎽ ⎽ ⎽ ⎽ io_sda
                    if s_cont_pulso = 0 then
                        io_scl <= '1';
                        io_sda <= '1';
                    if s_cont_pulso = 4 then
                        io_sda <= '0';
                    elsif s_cont_pulso = 6 then
                        io_scl <= '0';
                    end if;
                    -- edo. siguiente
                    if s_cont_pulso < c_pulso_0_7 then
                        s_cont_pulso <= s_cont_pulso + 1;
                        presente <= edo_start;
                    else
                        s_cont_pulso <= 0;
                        presente <= edo_frame1;
                    end if;

                -- ****** FRAME 1: SLAVE RECEIVER ADDRESS & RW ******
                -- (8 bits: orden de envío real="6543210 & rw", orden de envío lógico="0123456  & rw")
                when edo_frame1 =>
                    -- 0 1 2 3 4 5 6 7
                    -- ⎽ ⎽ ⎺ ⎺ ⎺ ⎺ ⎽ ⎽ io_scl
                    -- * * * * * * * * io_sda
                    if s_cont_pulso = 0 then
                        io_scl <= '0';
                        io_sda <= io_com;
                    elsif s_cont_pulso = 2 then
                        io_scl <= '1';
                    elsif s_cont_pulso = 6 then
                        io_scl <= '0';
                    elsif s_cont_pulso = 7 then
                        s_rw <= io_com; -- R/_W
                    end if;
                    -- edo. siguiente
                    if s_cont_pulso < c_pulso_0_7 then
                        s_cont_pulso <= s_cont_pulso + 1;
                        presente <= edo_frame1;
                    else
                        s_cont_pulso <= 0;
                        if bits < 7 then
                            bits <= bits + 1;
                            presente <= edo_frame1;
                        else
                            bits <= 0;
                            presente <= edo_ack1;
                        end if;
                    end if;

                when edo_ack1 =>
                    -- 0 1 2 3 4 5 6 7
                    -- ⎽ ⎽ ⎺ ⎺ ⎺ ⎺ ⎽ ⎽ io_scl
                    -- * * * * * * * * io_sda (LOW: ACK, HIGH: NOT ACK)
                    if s_cont_pulso = 0 then
                        io_scl <= '0';
                        io_sda <= 'Z';
                        s_ack <= io_sda;
                    elsif s_cont_pulso = 2 then
                        io_scl <= '1';
                    elsif s_cont_pulso = 6 then
                        io_scl <= '0';
                    end if;
                    -- edo. siguiente
                    if s_cont_pulso < c_pulso_0_7 then
                        s_cont_pulso <= s_cont_pulso + 1;
                        presente <= edo_ack1;
                    else
                        s_cont_pulso <= 0;
                        if s_ack = '0' then
                            if s_rw = '0' then
                                presente <= edo_write;
                            elsif s_rw = '1' then
                                presente <= edo_read;
                            end if;
                        else -- s_ack = '1' then
                            presente <= edo_error;
                        end if;
                    end if;

                -- ****** FRAME 2: WRITE DATA ******
                -- data (8 bits: orden de envío real="76543210", orden de envío lógico="01234567")
                when edo_write =>
                    -- 0 1 2 3 4 5 6 7
                    -- ⎽ ⎽ ⎺ ⎺ ⎺ ⎺ ⎽ ⎽ io_scl
                    -- * * * * * * * * io_sda
                    if s_cont_pulso = 0 then
                        io_scl <= '0';
                        io_sda <= io_com;
                    elsif s_cont_pulso = 2 then
                        io_scl <= '1';
                    elsif s_cont_pulso = 6 then
                        io_scl <= '0';
                    end if;
                    -- edo. siguiente
                    if s_cont_pulso < c_pulso_0_7 then
                        s_cont_pulso <= s_cont_pulso + 1;
                        presente <= edo_write;
                    else
                        s_cont_pulso <= 0;
                        if bits < 7 then
                            bits <= bits + 1;
                            presente <= edo_write;
                        else
                            bits <= 0;
                            presente <= edo_ack2_write;
                        end if;
                    end if;
                when edo_ack2_write =>
                    -- 0 1 2 3 4 5 6 7
                    -- ⎽ ⎽ ⎺ ⎺ ⎺ ⎺ ⎽ ⎽ io_scl
                    -- * * * * * * * * io_sda (LOW: ACK, HIGH: NOT ACK)
                    if s_cont_pulso = 0 then
                        io_scl <= '0';
                        io_sda <= 'Z';
                        s_ack <= io_com;
                    elsif s_cont_pulso = 2 then
                        io_scl <= '1';
                    elsif s_cont_pulso = 6 then
                        io_scl <= '0';
                    end if;
                    -- edo. siguiente
                    if s_cont_pulso < c_pulso_0_7 then
                        s_cont_pulso <= s_cont_pulso + 1;
                        presente <= edo_ack2_write;
                    else
                        s_cont_pulso <= 0;
                        if s_ack = '0' and ena = '1' then
                            presente <= edo_write;
                        elsif s_ack = '0' and ena = '0' then
                            presente <= edo_stop;
                        else -- s_ack = '1'
                            presente <= edo_error;
                        end if;
                    end if;
                
                -- ****** FRAME 2: READ DATA ******
                -- data (8 bits: orden de recepción real="76543210", orden de recepción lógico="01234567")
                when edo_read =>
                    -- 0 1 2 3 4 5 6 7
                    -- ⎽ ⎽ ⎺ ⎺ ⎺ ⎺ ⎽ ⎽ io_scl
                    -- * * * * * * * * io_sda
                    if s_cont_pulso = 0 then
                        io_scl <= '0';
                        io_sda <= 'Z';
                        io_com <= io_sda;
                    elsif s_cont_pulso = 2 then
                        io_scl <= '1';
                    elsif s_cont_pulso = 6 then
                        io_scl <= '0';
                    end if;
                    -- edo. siguiente
                    if s_cont_pulso < c_pulso_0_7 then
                        s_cont_pulso <= s_cont_pulso + 1;
                        presente <= edo_read;
                    else
                        s_cont_pulso <= 0;
                        if bits < 7 then
                            bits <= bits + 1;
                            presente <= edo_read;
                        else
                            bits <= 0;
                            presente <= edo_ack2_read;
                        end if;
                    end if;
                when edo_ack2_read =>
                    -- 0 1 2 3 4 5 6 7
                    -- ⎽ ⎽ ⎺ ⎺ ⎺ ⎺ ⎽ ⎽ io_scl
                    -- * * * * * * * * io_sda (LOW: ACK, HIGH: NOT ACK)
                    if s_cont_pulso = 0 then
                        io_scl <= '0';
                        io_sda <= 'Z';
                        s_ack <= io_com;
                    elsif s_cont_pulso = 2 then
                        io_scl <= '1';
                    elsif s_cont_pulso = 6 then
                        io_scl <= '0';
                    end if;
                    -- edo. siguiente
                    if s_cont_pulso < c_pulso_0_7 then
                        s_cont_pulso <= s_cont_pulso + 1;
                        presente <= edo_ack2_read;
                    else
                        s_cont_pulso <= 0;
                        if s_ack = '0' and ena = '1' then
                            presente <= edo_read;
                        elsif s_ack = '0' and ena = '0' then
                            presente <= edo_stop;
                        else -- s_ack = '1'
                            presente <= edo_error;
                        end if;
                    end if;
                
                -- ****** FIN DE I2C ******
                when edo_error =>
                    -- 0 1 2 3 4 5 6 7
                    -- ⎽ ⎽ ⎺ ⎺ ⎺ ⎺ ⎽ ⎽ io_scl
                    -- * * * * * * * * io_sda (LOW: ACK, HIGH: NOT ACK)
                    io_scl <= '1';
                    io_sda <= '1'';
                    o_error <= '1'';
                    -- edo. siguiente
                    presente <= edo_error;
                    if s_cont_pulso < c_pulso_0_7 then
                        s_cont_pulso <= s_cont_pulso + 1;
                        presente <= edo_error;
                    else
                        s_cont_pulso <= 0;
                        presente <= edo_error;
                    end if;

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
                        s_cont_pulso <= s_cont_pulso + 1;
                        presente <= edo_stop;
                    else
                        s_cont_pulso <= 0;
                        presente <= edo_iddle;
                    end if;
            end case;
        end if;
    end process;
end architecture;