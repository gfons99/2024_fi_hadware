-- ****************************************
-- tittle:	Controlador para el ADS1115
-- author:	
-- date:	2024-04-05
-- description:
-- * SCL = 1MHz
-- * DCL = 1MHz

-- Gazi, & Arli. (2021). State Machines using VHDL. FPGA Implementation of Serial Communication and Display Protocols. Switzerland. Springer.
-- ****************************************

library ieee;
use ieee.std_logic_1164.all;
entity fsm_i2c is
    port(
        clk_10mhz: in std_logic;
        rst, wr_enable: in std_logic;

        scl, dcl: out std_logic;

        sda: inout std_logic
    );
end entity;

architecture logic_flow of fsm_i2c  is
    -- clk4mhz: process(clk_100mhz)
    -- ….
    -- end process;
    -- clk1mhz: process (clk_4mhz)
    -- ….
    -- end process;

type state is(st_idle, st0_start, st1_txslaveaddress, st2_ack0, st3_txdata, st4_ack1, st5_stop);

constant data: std_logic_vector(7 downto 0):="11101100";
constant slave_address_with_wrt_flg: std_logic_vector(7 downto 0):="11101100";       
constant max_length: natural := 8;

signal present_state, next_state: state;
signal scl_buss: 		std_logic;
signal dcl_buss: 		std_logic;
signal ack_bits:		std_logic_vector(1 downto 0);
signal data_index: 	natural range 0 to max_length -1;
signal timer: 			natural range 0 to max_length;
signal count: 			natural range 0 to 11:=0;

begin
    -- scl <= scl_buss;
    dcl <= dcl_buss;

    p1: process(dcl_buss, rst)
    begin
        if(rst ='1') then
            present_state <= st_idle;
            data_index <= 0;
        elsif(dcl_buss'event and dcl_buss='1') then
            if(data_index = timer-1) then
                present_state <= next_state;
                data_index <= 0;
            else
                data_index <= data_index + 1;
            end if; 
        end if;
    end process;

    p2: process(dcl_buss)
    begin
        if(dcl_buss'event and dcl_buss = '1') then
            if(present_state = st2_ack0) then
                ack_bits(0) <= sda;
            elsif( present_state = st4_ack1) then
                ack_bits(1) <= sda;        
            end if;
        end if;
    end process;

    p3: process(present_state, wr_enable, data_index, dcl_buss) 
    begin
        case present_state is
            when st_idle =>
                scl <= '1';
                sda <= '1';
                timer <= 1;
                if(wr_enable='1') then
                    next_state <= st0_start;
                else
                    next_state <= st_idle;
                end if;      
            when st0_start =>
                sda <= dcl_buss;
                timer <= 1;
                next_state <= st1_txslaveaddress;
                scl <= '1';
            when st1_txslaveaddress =>
                sda <= slave_address_with_wrt_flg(7-data_index);
                timer <= 8;
                next_state <= st2_ack0; 
                scl <= scl_buss;
            when st2_ack0=>
                sda <= '0'; -- z
                timer <= 1;
                next_state <= st3_txdata; 
                scl <= scl_buss;          
            when st3_txdata =>
                sda <= data(7-data_index);
                timer <= 8;
                next_state <= st4_ack1; 
                scl <= scl_buss;
            when st4_ack1=>
                sda <= '0'; -- z
                timer <= 1;
                next_state <= st5_stop; 
                scl <= scl_buss;
            when st5_stop =>
                sda <= not dcl_buss;
                timer <= 1;
                next_state <= st_idle; 
                scl <= '1';
        end case;
    end process;
end architecture;
