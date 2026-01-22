-- uart_rx.vhd
-- part of fr-vhdl
-- CERN-OHL-W-2.0 license
-- 2025

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

ENTITY uart_rx IS
    GENERIC
    (
        g_sys_clk_hz    : positive;
        g_uart_baud     : positive
    );
    PORT
    (
        i_clk        : IN    std_logic;

        i_uart_rx    : IN    std_logic;

        o_data       :   OUT std_logic_vector(7 downto 0);
        o_data_valid :   OUT std_logic
    );
END uart_rx;

ARCHITECTURE RTL OF uart_rx IS

    TYPE     T_state IS (IDLE, START, DATA, STOP, ERROR);
    SIGNAL   r_state_cur          : T_state                               := IDLE;
    SIGNAL   w_state_next         : T_state;

    CONSTANT C_clk_cnt_mod        : integer                               := g_sys_clk_hz / g_uart_baud;
    SIGNAL   r_clk_cnt            : integer RANGE 0 TO C_clk_cnt_mod-1    :=  0;

    CONSTANT C_bit_cnt_mod        : integer                               :=  8;
    SIGNAL   r_bit_cnt            : integer RANGE 0 TO C_bit_cnt_mod-1    :=  0;

    SIGNAL   r_data               : std_logic_vector(7 downto 0)          := (OTHERS => '0');
    SIGNAL   r_data_valid         : std_logic                             := '0';

BEGIN

    o_data       <= r_data;
    o_data_valid <= r_data_valid;


    P_update_state : PROCESS(i_clk)
    BEGIN
        IF (rising_edge(i_clk)) THEN
            r_state_cur <= w_state_next;
        END IF;
    END PROCESS;

    P_decide_next_state : PROCESS(r_state_cur, i_uart_rx, r_clk_cnt, r_bit_cnt)
    BEGIN

        w_state_next <= r_state_cur;

        CASE r_state_cur IS
            WHEN IDLE =>
                IF (i_uart_rx = '0') THEN
                    w_state_next <= START;
                END IF;

            WHEN START =>
                IF (r_clk_cnt = (C_clk_cnt_mod-1)/2) THEN
                    w_state_next <= DATA;
                END IF;

            WHEN DATA =>
                IF (r_clk_cnt = C_clk_cnt_mod-1) THEN
                    IF (r_bit_cnt = C_bit_cnt_mod-1) THEN
                        w_state_next <= STOP;
                    END IF;
                END IF;

            WHEN STOP =>
                IF (r_clk_cnt = C_clk_cnt_mod-1) THEN
                    IF (i_uart_rx /= '1') THEN
                        w_state_next <= ERROR;
                    ELSE
                        w_state_next <= IDLE;
                    END IF;
                END IF;

            WHEN ERROR =>
                IF (i_uart_rx = '1') THEN
                    w_state_next <= IDLE;
                END IF;

        END CASE;

    END PROCESS;

    P_uart_shift_register : PROCESS(i_clk)
    BEGIN
        IF (rising_edge(i_clk)) THEN
            IF (r_state_cur = DATA) THEN
                IF (r_clk_cnt = C_clk_cnt_mod-1) THEN
                    r_data <= i_uart_rx & r_data(7 downto 1); --UART is LSb first
                    IF (r_bit_cnt < C_bit_cnt_mod-1) THEN
                        r_bit_cnt <= r_bit_cnt + 1;
                    END IF;
                END IF;
            ELSE
                r_bit_cnt <= 0;
            END IF;
        END IF;
    END PROCESS;

    P_uart_clk : PROCESS(i_clk)
    BEGIN
        IF (rising_edge(i_clk)) THEN
            IF (r_state_cur /= IDLE AND r_state_cur /= ERROR) THEN
                IF (r_state_cur = START AND w_state_next = DATA) THEN
                    r_clk_cnt <= 0;
                ELSE
                    IF (r_clk_cnt < C_clk_cnt_mod-1) THEN
                        r_clk_cnt <= r_clk_cnt + 1;
                    ELSE
                        r_clk_cnt <= 0;
                    END IF;
                END IF;
            ELSE
                r_clk_cnt <= 0;
            END IF;
        END IF;
    END PROCESS;

    P_data_valid : PROCESS(i_clk)
    BEGIN
        IF (rising_edge(i_clk)) THEN
            IF (r_state_cur = STOP AND w_state_next = IDLE) THEN
                r_data_valid <= '1';
            ELSE
                r_data_valid <= '0';
            END IF;
        END IF;
    END PROCESS;

END ARCHITECTURE;
