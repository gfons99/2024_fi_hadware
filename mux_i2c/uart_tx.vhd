-- ****************************************
-- tittle: UART TX
-- author: M.I. B.E.A.S
-- date: 2023
-- description: *
-- ****************************************
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity uart_tx is
	port(
		clk: in std_logic; -- CLK_50
		tx_out: out std_logic; -- 
		busy: in std_logic; -- inicia comunicacion --SWITCH
		-- rx_in: in std_logic_vector(11 downto 0)
		mx,cx,dx,ux: in integer range 0 to 9
	);
end uart_tx;

architecture beas of uart_tx is
signal start: std_logic;
signal prescl: integer range 0 to 434 := 0; -- baudaje = 50mhz/prescl
signal index: integer range 0 to 9 := 0; -- selecciona que bit se envia
signal data_frame: std_logic_vector(9 downto 0) ; -- vector de 8 bits de datos, bit de start y bit de stop
signal tx_flag: std_logic := '0';
signal data: std_logic_vector(7 downto 0) := (others => '0'); -- dato de 8 bits
-- signal hex_data: std_logic_vector(7 downto 0) := (others => '0');
signal hex_mx,hex_cx,hex_dx,hex_ux: std_logic_vector(7 downto 0) := (others => '0');
signal place: integer range 0 to 8; -- tamaÑo de array_tx
signal delay: integer := 10000; -- retardo entre datos
signal conta: integer := 0;
-----------------------------------------------------------------------------------------
type array_tx is array (0 to 8) of std_logic_vector(7 downto 0); -- no de caracteres por línea
signal asc_data : array_tx := (x"30",x"30",x"30",x"2E",x"30",x"20",x"B0",x"43",x"0a"); -- x0a salto de linea

begin
	-- preparar la cadena de datos a enviar
	process(clk, busy)
	begin
		asc_data(0) <= hex_mx; -- pongo el dato que asigno
		asc_data(1) <= hex_cx; -- pongo el dato que asigno
		asc_data(2) <= hex_dx; -- pongo el dato que asigno
		asc_data(4) <= hex_ux; -- pongo el dato que asigno
		if busy = '1' then
			if falling_edge(clk) then
				if conta = delay then
					conta <= 0;
					start <= '1';
					data <= asc_data(place);
					if place = 8 then
						place <= 0;
					else
						place <= place + 1;
					end if;
				else
					conta <= conta + 1;
					start <= '0';
				end if;
			end if;
		end if;
	end process;
	
	-- enviar el dato
	process(clk)
	begin
		if rising_edge(clk) then
			if (tx_flag = '0' and start = '1') then 
				tx_flag <= '1';
				data_frame(0) <= '0'; -- bit de start
				data_frame(9) <= '1'; -- bit de stop				
				data_frame(8 downto 1) <= data; -- 8 bits (datos)
			end if;
			
			if tx_flag = '1' then 
				if prescl < 433 then
					prescl <= prescl + 1;
				else
					prescl <= 0;
			end if;
				
			if prescl = 217 then -- (434/2)
				tx_out <= data_frame (index);
				if index < 9 then
					index <= index + 1;
				else
					tx_flag <= '0';
					index <= 0;
				end if;
			end if;
		end if;
	end if;		
end process;
	
	with (mx) select -- mux ascii (hex)
		hex_mx <=
			x"30" when 0, -- 0
			x"31" when 1, -- 1
			x"32" when 2, -- 2
			x"33" when 3, -- 3
			x"34" when 4, -- 4
			x"35" when 5, -- 5
			x"36" when 6, -- 6
			x"37" when 7, -- 7
			x"38" when 8, -- 8
			x"39" when 9, -- 9
			x"23" when others;
	with (cx) select -- mux ascii (hex)
		hex_cx <=
			x"30" when 0, -- 0
			x"31" when 1, -- 1
			x"32" when 2, -- 2
			x"33" when 3, -- 3
			x"34" when 4, -- 4
			x"35" when 5, -- 5
			x"36" when 6, -- 6
			x"37" when 7, -- 7
			x"38" when 8, -- 8
			x"39" when 9, -- 9
			x"23" when others;
	with (dx) select -- mux ascii (hex)
		hex_dx <=
			x"30" when 0, -- 0
			x"31" when 1, -- 1
			x"32" when 2, -- 2
			x"33" when 3, -- 3
			x"34" when 4, -- 4
			x"35" when 5, -- 5
			x"36" when 6, -- 6
			x"37" when 7, -- 7
			x"38" when 8, -- 8
			x"39" when 9, -- 9
			x"23" when others;
	with (ux) select -- mux ascii (hex)
		hex_ux <=
			x"30" when 0, -- 0
			x"31" when 1, -- 1
			x"32" when 2, -- 2
			x"33" when 3, -- 3
			x"34" when 4, -- 4
			x"35" when 5, -- 5
			x"36" when 6, -- 6
			x"37" when 7, -- 7
			x"38" when 8, -- 8
			x"39" when 9, -- 9
			x"23" when others;
		

end beas;