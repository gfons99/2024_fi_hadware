-- ****************************************
-- tittle: UART RX
-- author: M.I. B.E.A.S
-- date: 2023
-- description: *
-- ****************************************
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity uart_rx is
    port (
        rx_in : in  std_logic;  -- uart receive signal
		  clk: in  std_logic;  
        data_out : out std_logic_vector(7 downto 0):="00000000"  -- received ascii character
    );
end entity;

architecture behavioral of uart_rx is
--	signal b_ini: std_logic := '1';
	signal ini: std_logic := '1';
	signal fin: std_logic := '1';
	signal index: integer range 0 to 7 := 0;
	signal faux: integer range 0 to 433 := 0;
	signal delay: integer range 0 to 49999999:= 0;
begin
	process(clk,rx_in) -- recibir un dato
	
	begin
	-- RECEPCIÓN DE DATOS (RX_IN)
	if rising_edge(clk) then
		-- Si se recibe el bit de inicio de rx_in, se inicia la comunicación
		if (ini = '1' and rx_in = '0') then 
			ini <= '0';
			-- data_out <= "10101010";
		end if;
		-- Esperar a que pase el bit de inicio
--		if b_ini = '0' then
--			if faux < 433 then
--				faux <= faux + 1;
--			else
--				faux <= 0;
--				b_ini <= '1';
--				ini <= '0';
--			end if;
--		end if;
		
		-- Si la comunicación ha sido iniciada
		if ini = '0' and fin = '1' then
			-- Si estamos dentro de los 8 bits de datos, los guardamos
			if index = 7 then
				index <= 0;
				fin <= '0';
			else
				-- Contamos un símbolo completo
				if faux < 433 then
					faux <= faux + 1;
					-- Tomamos el valor a medio símbolo
					if faux = 217 then -- (434/2)
						
						data_out(index) <= rx_in;
						index <= index + 1;
					end if;
				else
					faux <= 0;
				end if;

			end if;
		end if;
		-- Si ya obtuvimos 8 bits, ignoramos el resto de la comunicación
		if fin = '0' then
			if delay < 49999999 then
				delay <= delay + 1;
			else
				delay <= 0;
				ini <= '1';
				fin <= '1';
				-- data_out <= "11110000";
			end if;
		end if;
	end if;
	-- FIN RECEPCIÓN DE DATOS (RX_IN)
	end process;
end architecture;