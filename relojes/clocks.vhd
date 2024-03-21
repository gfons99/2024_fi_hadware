library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity clocks is
    port (
        clk_in : in std_logic;     -- entrada del reloj principal
        clk_out : out std_logic    -- salida del reloj para zigbee
    );
end clocks;

architecture behavioral of clocks is
    signal counter : integer range 0 to 4999 := 0;  -- contador para el divisor de frecuencia
    signal clk_div : std_logic := '0';              -- salida del divisor de frecuencia

    constant divisor : integer := 5000;             -- divisor de frecuencia para el reloj de zigbee
begin
    process (clk_in)
    begin
        if rising_edge(clk_in) then
            -- incrementar el contador
            counter <= counter + 1;
            
            -- divisor de frecuencia para generar el reloj de zigbee
            if counter = divisor - 1 then
                counter <= 0;
                clk_div <= not clk_div;
            end if;
        end if;
    end process;

    -- asignar la salida del divisor de frecuencia al reloj de zigbee
    clk_out <= clk_div;
end behavioral;
