library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity uart_tx is
    generic (
        CLK_HZ : integer := 27_000_000;
        BAUD   : integer := 9600
    );
    port (
        clk     : in  std_logic;
        reset   : in  std_logic;
        start   : in  std_logic;
        data_in : in  std_logic_vector(7 downto 0);
        tx      : out std_logic;
        busy    : out std_logic;
        done    : out std_logic
    );
end entity;

architecture rtl of uart_tx is
    constant UART_DIV : integer := (CLK_HZ + BAUD/2) / BAUD;

    signal busy_i : std_logic := '0';
    signal done_i : std_logic := '0';
    signal tx_i   : std_logic := '1';
    signal tx_reg : std_logic_vector(7 downto 0) := (others => '0');
    signal cnt    : integer range 0 to UART_DIV-1 := 0;
    signal bit_idx: integer range 0 to 9 := 0;
begin
    tx <= tx_i;
    busy <= busy_i;
    done <= done_i;

    process(clk)
    begin
        if rising_edge(clk) then
            done_i <= '0';

            if reset = '1' then
                busy_i <= '0';
                tx_i <= '1';
                tx_reg <= (others => '0');
                cnt <= 0;
                bit_idx <= 0;

            elsif busy_i = '0' then
                tx_i <= '1';
                if start = '1' then
                    busy_i <= '1';
                    tx_reg <= data_in;
                    cnt <= 0;
                    bit_idx <= 0;
                    tx_i <= '0'; -- start bit
                end if;

            else
                if cnt = UART_DIV-1 then
                    cnt <= 0;
                    case bit_idx is
                        when 0 => bit_idx <= 1; tx_i <= tx_reg(0);
                        when 1 => bit_idx <= 2; tx_i <= tx_reg(1);
                        when 2 => bit_idx <= 3; tx_i <= tx_reg(2);
                        when 3 => bit_idx <= 4; tx_i <= tx_reg(3);
                        when 4 => bit_idx <= 5; tx_i <= tx_reg(4);
                        when 5 => bit_idx <= 6; tx_i <= tx_reg(5);
                        when 6 => bit_idx <= 7; tx_i <= tx_reg(6);
                        when 7 => bit_idx <= 8; tx_i <= tx_reg(7);
                        when 8 => bit_idx <= 9; tx_i <= '1'; -- stop bit
                        when others =>
                            busy_i <= '0';
                            done_i <= '1';
                            tx_i <= '1';
                    end case;
                else
                    cnt <= cnt + 1;
                end if;
            end if;
        end if;
    end process;
end architecture;
