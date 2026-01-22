-- uart.vhd
-- part of fr-vhdl
-- CERN-OHL-W-2.0 license
-- 2026

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

PACKAGE uart IS

    COMPONENT uart_rx IS
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
    END COMPONENT uart_rx;

    COMPONENT uart_tx IS
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
    END COMPONENT uart_tx;

END PACKAGE uart;

PACKAGE BODY uart IS

END PACKAGE BODY uart;
