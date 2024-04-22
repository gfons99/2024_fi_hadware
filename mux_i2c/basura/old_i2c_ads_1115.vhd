-- ****************************************
-- Práctica 04: "Semáforo FSM"
-- F.R.G.M
-- 14 de marzo de 2023
-- ****************************************

library ieee;
use ieee.std_logic_1164.all;

entity i2c_ads_1115 is
	port(
	-- entradas:
	dcl: in std_logic;
	send_dat_conf: in std_logic;
	sel_adc_ch: in std_logic_vector(1 downto 0);
	dat_adc: in std_logic;

	-- salidas:
	rst, ena: out std_logic;
	dat_conf: out std_logic
	);
end entity;

architecture frgm of i2c_ads_1115 is

	component i2c_fsm
		port (
			-- entradas:
			dcl: in std_logic;
			rst, ena: in std_logic;
	
			datos: in std_logic;
			i_sda: in std_logic;
			-- salidas:
			sel_scl: out std_logic_vector(1 downto 0) := "01"; -- 0: scl    -- 1: '1'
			sel_sda: out std_logic_vector(1 downto 0) := "01"; -- 0: dcl    -- 1: '1' o datos
	
			o_sda: out std_logic := '1';
			o_slave_error: out std_logic
		);
	end component;

	type estados is (frame1,frame2,frame3,frame4,frame5);
	signal presente: estados := frame1;

	signal dir_analog: std_logic_vector(7 downto 0);
	signal bits : integer range 0 to 7 := 0;

	-- DATOS
	-- (r/_w): '1' read, '0' write
	constant dir_slave_rw: std_logic_vector(7 downto 0) := "10010000"; -- dirección del esclavo & rw
	signal mem_adc: std_logic_vector(15 downto 0);

begin
	--b1: 

	process(dcl, send_dat_conf)
    begin
		if rising_edge(dcl) then
			if send_dat_conf = '1' then
				case frame1 is
					when frame1 =>
						-- frame. siguiente
						if bits < 7 then
							presente <= frame1;
							bits <= bits + 1;
						else
							presente <= frame2;
							bits <= 0;
						end if;
						-- entradas / salidas
						dat_conf <= dir_slave_rw(bits);
						
					when frame2 =>
						-- frame. siguiente
						if bits < 7 then
							presente <= frame2;
							bits <= bits + 1;
						else
							presente <= frame3;
							bits <= 0;
						end if;
						-- entradas / salidas
						dir_analog <= "000000" and sel_adc_ch;
						dat_conf <= dir_analog(bits);

					when frame3 =>
						-- frame. siguiente
						if bits < 7 then
							presente <= frame3;
							bits <= bits + 1;
						else
							presente <= frame4;
							bits <= 0;
						end if;
						-- entradas / salidas
						dat_conf <= dir_slave_rw(bits);
					
					-- (8 bits: orden de recepción real="15,14,13,12,11,10,9,8", orden de recepción lógico="0,1,2,3,4,5,6,7")
					when frame4 =>
						-- frame. siguiente
						if bits < 7 then
							presente <= frame4;
							bits <= bits + 1;
						else
							presente <= frame5;
							bits <= 8;
						end if;
						-- entradas / salidas
						mem_adc(bits) <= dat_adc;

					-- (8 bits: orden de recepción real="7,6,5,4,3,2,1,0", orden de recepción lógico="8,9,10,11,12,13,14,15")
					when frame5 =>
						-- frame. siguiente
						if bits < 15 then
							presente <= frame4;
							bits <= bits + 1;
						else
							presente <= frame5;
							bits <= 8;
						end if;
						-- entradas / salidas
						mem_adc(bits) <= dat_adc;
				end case;
			end if;
		end if;
	end process;
	
end frgm;
