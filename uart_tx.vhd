-- uart_tx.vhd
-- part of fr-vhdl
-- CERN-OHL-W-2.0 license
-- 2025

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY uart_tx IS
    GENERIC
    (
        g_sys_clk_hz    : positive;
        g_uart_baud     : positive
    );
    PORT
    (
        i_clk        : IN    std_logic;

        i_data       : IN    std_logic_vector(7 downto 0);
        i_data_valid : IN    std_logic;

        o_idle       :   OUT std_logic;

        o_uart_tx    :   OUT std_logic
    );
END uart_tx;

ARCHITECTURE RTL OF uart_tx IS

    TYPE     T_state IS (IDLE, START, DATA, STOP);
    SIGNAL   r_state_cur          : T_state                            := IDLE;
    SIGNAL   w_state_next         : T_state;

    CONSTANT C_clk_cnt_mod        : integer                            := g_sys_clk_hz / g_uart_baud;
    SIGNAL   r_clk_cnt            : integer RANGE 0 TO C_clk_cnt_mod-1 :=  0;

    CONSTANT C_bit_cnt_mod        : integer                            :=  8;
    SIGNAL   r_bit_cnt            : integer RANGE 0 TO C_bit_cnt_mod-1 :=  0;

    SIGNAL   r_data_in            : std_logic_vector(7 downto 0)       := (OTHERS => '0');

    SIGNAL   r_data_out           : std_logic                             := '1';

BEGIN

    o_uart_tx <= r_data_out;

    o_idle    <= '1' WHEN w_state_next = IDLE ELSE '0';


    P_update_state : PROCESS(i_clk)
    BEGIN
        IF (rising_edge(i_clk)) THEN
            r_state_cur <= w_state_next;
        END IF;
    END PROCESS;

    P_decide_next_state : PROCESS(r_state_cur,
                                  i_data_valid,
                                  r_clk_cnt,
                                  r_bit_cnt)
    BEGIN

        w_state_next <= r_state_cur;

        CASE r_state_cur IS
            WHEN IDLE =>
                IF (i_data_valid = '1') THEN
                    w_state_next <= START;
                END IF;

            WHEN START =>
                IF (r_clk_cnt = C_clk_cnt_mod-1) THEN
                    w_state_next <= DATA;
                END IF;

            WHEN DATA =>
                IF (r_clk_cnt = C_clk_cnt_mod-1 AND r_bit_cnt = C_bit_cnt_mod-1) THEN
                    w_state_next <= STOP;
                END IF;

            WHEN STOP =>
                IF (r_clk_cnt = C_clk_cnt_mod-1) THEN
                    w_state_next <= IDLE;
                END IF;

        END CASE;

    END PROCESS;

    P_latch_data : PROCESS(i_clk)
    BEGIN
        IF (rising_edge(i_clk)) THEN
            IF (r_state_cur = IDLE AND i_data_valid = '1') THEN
                r_data_in <= i_data;
            END IF;
        END IF;
    END PROCESS;

    P_output_data : PROCESS(i_clk)
    BEGIN
        IF (rising_edge(i_clk)) THEN
            CASE r_state_cur IS
                WHEN START =>
                    r_data_out <= '0';
                WHEN DATA =>
                    r_data_out <= r_data_in(r_bit_cnt);
                WHEN STOP =>
                    r_data_out <= '1';
                WHEN OTHERS =>
                    r_data_out <= '1';
            END CASE;
        END IF;
    END PROCESS;

    P_bit_cnt : PROCESS(i_clk)
    BEGIN
        IF (rising_edge(i_clk)) THEN
            IF (r_state_cur = DATA) THEN
                IF (r_clk_cnt = C_clk_cnt_mod-1) THEN
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
            IF (r_state_cur /= IDLE) THEN
                IF (r_clk_cnt < C_clk_cnt_mod-1) THEN
                    r_clk_cnt <= r_clk_cnt + 1;
                ELSE
                    r_clk_cnt <= 0;
                END IF;
            ELSE
                r_clk_cnt <= 0;
            END IF;
        END IF;
    END PROCESS;


END ARCHITECTURE;
