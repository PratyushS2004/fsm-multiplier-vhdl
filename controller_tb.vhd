----------------------------------------------------------------------------------
-- Testbench for Project 3 Controller
-- Entity under test:
--   entity controller is
--     Port (
--       CLK  : in  STD_LOGIC;
--       M    : in  STD_LOGIC_VECTOR (4 downto 1);
--       N    : in  STD_LOGIC_VECTOR (4 downto 1);
--       ST   : in  STD_LOGIC;
--       DONE : out STD_LOGIC;
--       R    : out STD_LOGIC_VECTOR (8 downto 1)
--     );
--   end controller;
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;  -- keep for compatibility with older code
use IEEE.NUMERIC_STD.ALL;

entity controller_tb is
end controller_tb;

architecture tb of controller_tb is

    -- DUT inputs
    signal CLK   : std_logic := '0';
    signal ST    : std_logic := '0';
    signal M, N  : std_logic_vector(4 downto 1) := (others => '0');

    -- DUT outputs
    signal DONE  : std_logic;
    signal R     : std_logic_vector(8 downto 1);

    -- Clock period
    constant CLK_PERIOD : time := 10 ns;

begin

    -------------------------------------------------------------------------
    -- Instantiate DUT
    -------------------------------------------------------------------------
    DUT: entity work.controller
    port map(
        CLK  => CLK,
        M    => M,
        N    => N,
        ST   => ST,
        DONE => DONE,
        R    => R
    );

    -------------------------------------------------------------------------
    -- Clock generation
    -------------------------------------------------------------------------
    clk_process : process
    begin
        CLK <= '0';
        wait for CLK_PERIOD/2;
        CLK <= '1';
        wait for CLK_PERIOD/2;
    end process;

    -------------------------------------------------------------------------
    -- Stimulus + self-checking
    -------------------------------------------------------------------------
    stim : process
        -- run one test vector
        procedure run_test(
            constant m_in : std_logic_vector(4 downto 1);
            constant n_in : std_logic_vector(4 downto 1)
        ) is
            variable exp_prod  : integer;
            variable got_prod  : integer;
            variable cycles    : integer := 0;
        begin
            -- apply inputs
            M <= m_in;
            N <= n_in;

            -- start pulse (1 clock)
            ST <= '1';
            wait until rising_edge(CLK);
            ST <= '0';

            -- wait for DONE with timeout
            cycles := 0;
            while (DONE = '0' and cycles < 50) loop   -- 50 cycles timeout
                wait until rising_edge(CLK);
                cycles := cycles + 1;
            end loop;

            if DONE = '0' then
                assert false
                    report "TIMEOUT: DONE did not assert for M=" &
                           integer'image(to_integer(unsigned(m_in))) &
                           " N=" & integer'image(to_integer(unsigned(n_in)))
                    severity error;
            end if;

            -- compute expected and actual product
            exp_prod := to_integer(unsigned(m_in)) * to_integer(unsigned(n_in));
            got_prod := to_integer(unsigned(R));

            if got_prod /= exp_prod then
                assert false
                    report "FAIL: M=" &
                           integer'image(to_integer(unsigned(m_in))) &
                           " N=" &
                           integer'image(to_integer(unsigned(n_in))) &
                           "  Expected=" & integer'image(exp_prod) &
                           "  Got=" & integer'image(got_prod)
                    severity error;
            else
                report "PASS: M=" &
                       integer'image(to_integer(unsigned(m_in))) &
                       " N=" &
                       integer'image(to_integer(unsigned(n_in))) &
                       "  PRODUCT=" & integer'image(got_prod);
            end if;

            -- give controller a couple of clocks to return to idle state
            wait until rising_edge(CLK);
            wait until rising_edge(CLK);
        end procedure;

    begin
        -- allow initialization
        wait for 20 ns;

        -- Test vectors
        -- zeros
        run_test("0000", "0000"); -- 0 * 0 = 0
        run_test("0000", "1010"); -- 0 * 10 = 0
        run_test("0111", "0000"); -- 7 * 0 = 0

        -- small numbers
        run_test("0001", "0001"); -- 1 * 1 = 1
        run_test("0010", "0011"); -- 2 * 3 = 6
        run_test("0011", "0100"); -- 3 * 4 = 12

        -- medium range
        run_test("0101", "0110"); -- 5 * 6 = 30
        run_test("0111", "1000"); -- 7 * 8 = 56
        run_test("0110", "0011"); -- 6 * 3 = 18

        -- asymmetric / mixed
        run_test("1001", "0111"); -- 9 * 7 = 63
        run_test("1010", "0011"); -- 10 * 3 = 30
        run_test("0100", "1101"); -- 4 * 13 = 52

        -- "identity" style cases
        run_test("1111", "0001"); -- 15 * 1 = 15
        run_test("0001", "1110"); -- 1 * 14 = 14

        -- larger products
        run_test("1010", "1010"); -- 10 * 10 = 100
        run_test("1100", "1111"); -- 12 * 15 = 180
        run_test("1111", "1111"); -- 15 * 15 = 225

        report "All tests completed." severity note;
        wait;   -- stop simulation
    end process;

end tb;
