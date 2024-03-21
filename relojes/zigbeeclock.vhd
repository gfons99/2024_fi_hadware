library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity zigbeeclock is
    port (
        clk_out : out std_logic;  -- salida del reloj
        reset : in std_logic       -- entrada de reset
    );
end zigbeeclock;

architecture behavioral of zigbeeclock is
    constant clock_freq : natural := 2400000000;  -- frecuencia del reloj en hz (2.4 ghz)
    constant bit_rate : natural := 250000;       -- tasa de bits en bps (250 kbps)
    signal counter : unsigned(31 downto 0) := (others => '0');
    signal period_count : natural;
    signal clk_internal : std_logic := '0';
begin
    -- calcula el número de ciclos de reloj por bit
    period_count <= clock_freq / bit_rate;

    -- proceso para generar el reloj
    clk_process : process(reset)
    begin
        if reset = '1' then
            counter <= (others => '0');  -- reinicia el contador
            clk_internal <= '0';         -- inicia el reloj en bajo
        elsif rising_edge(clk_internal) then
            if counter = period_count - 1 then
                counter <= (others => '0');  -- reinicia el contador
                clk_internal <= not clk_internal;  -- invierte el reloj
            else
                counter <= counter + 1;  -- incrementa el contador
            end if;
        end if;
    end process;

    -- asigna el reloj interno a la salida
    clk_out <= clk_internal;

end behavioral;
