library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity uart_rx is
    generic (
        CLK_HZ : integer := 27_000_000;
        BAUD   : integer := 9600
    );
    port (
        clk      : in  std_logic;
        reset    : in  std_logic;
        rx       : in  std_logic;
        data_out : out std_logic_vector(7 downto 0);
        valid    : out std_logic
    );
end entity;

architecture rtl of uart_rx is
    constant UART_DIV      : integer := (CLK_HZ + BAUD/2) / BAUD;
    constant UART_HALF_DIV : integer := UART_DIV / 2;

    type state_t is (IDLE, START_BIT, DATA_BITS, STOP_BIT, CLEANUP);
    signal state    : state_t := IDLE;
    signal rx_meta  : std_logic := '1';
    signal rx_sync  : std_logic := '1';
    signal cnt      : integer range 0 to UART_DIV-1 := 0;
    signal bit_idx  : integer range 0 to 7 := 0;
    signal shift    : std_logic_vector(7 downto 0) := (others => '0');
    signal data_i   : std_logic_vector(7 downto 0) := (others => '0');
    signal valid_i  : std_logic := '0';
begin
    data_out <= data_i;
    valid <= valid_i;

    -- Two-flop synchronizer for asynchronous UART RX.
    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                rx_meta <= '1';
                rx_sync <= '1';
            else
                rx_meta <= rx;
                rx_sync <= rx_meta;
            end if;
        end if;
    end process;

    process(clk)
    begin
        if rising_edge(clk) then
            valid_i <= '0';

            if reset = '1' then
                state <= IDLE;
                cnt <= 0;
                bit_idx <= 0;
                shift <= (others => '0');
                data_i <= (others => '0');
            else
                case state is
                    when IDLE =>
                        cnt <= 0;
                        bit_idx <= 0;
                        if rx_sync = '0' then
                            state <= START_BIT;
                        end if;

                    when START_BIT =>
                        if cnt = UART_HALF_DIV then
                            if rx_sync = '0' then
                                cnt <= 0;
                                state <= DATA_BITS;
                            else
                                cnt <= 0;
                                state <= IDLE;
                            end if;
                        else
                            cnt <= cnt + 1;
                        end if;

                    when DATA_BITS =>
                        if cnt < UART_DIV-1 then
                            cnt <= cnt + 1;
                        else
                            cnt <= 0;
                            shift(bit_idx) <= rx_sync;
                            if bit_idx < 7 then
                                bit_idx <= bit_idx + 1;
                            else
                                bit_idx <= 0;
                                state <= STOP_BIT;
                            end if;
                        end if;

                    when STOP_BIT =>
                        if cnt < UART_DIV-1 then
                            cnt <= cnt + 1;
                        else
                            cnt <= 0;
                            if rx_sync = '1' then
                                data_i <= shift;
                                valid_i <= '1';
                            end if;
                            state <= CLEANUP;
                        end if;

                    when CLEANUP =>
                        state <= IDLE;
                end case;
            end if;
        end if;
    end process;
end architecture;
