----------------------------------------------------------------------------------
-- Institution: The Ohio State University
-- Engineers: 
--    Sreekar Kutagulla - Designer for control sequencing logic
--    Pratyush Shrestha - Debugging and signal mapping
--
-- File Created: 12/01/2025   Time: 14:03:19
-- Component:    System Controller
-- Source File:  controller (Behavioral)
-- Course Project: Project 3
-- Tools Used: ISE 14.7
--
-- Description:
--   Main control unit supervising the multiply-and-shift process. 
--
-- Revision History:
--   Rev 0.02 - Initial implementation, adjusted mapping
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity controller is
    Port ( CLK : in STD_LOGIC;
           M, N : in STD_LOGIC_VECTOR (4 downto 1);
           ST   : in STD_LOGIC;
           DONE : out STD_LOGIC;
           R    : out STD_LOGIC_VECTOR (8 downto 1));
end controller;



architecture Behavioral of controller is
    signal State : integer range 0 to 9;
    signal ACC   : std_logic_vector(8 downto 0);      -- ACC register (comment added by Sreekar)
    alias Z      : std_logic is ACC(0);               -- LSB reference (defined by Pratyush)
	
begin

    -- Output assignment for result vector (formatted by Sreekar)
    R <= ACC(7 downto 0);

    process (CLK)
    begin
        if CLK'event and CLK = '1' then               -- rising-edge driven process (noted by Sreekar)

            case State is

                when 0 =>                             -- waiting for ST to start (comment by Pratyush)
                    if ST = '1' then
                        ACC(8 downto 4) <= "00000";    -- clear top bits (added by Sreekar)
                        ACC(3 downto 0) <= N;          -- load in multiplier bits (added by Sreekar)
                        State <= 1;
                    end if;

                when 1 | 3 | 5 | 7 =>                 -- add-or-skip stage logic (construct credited to Sreekar)
                    if Z = '1' then                   -- conditional add check (written by Sreekar)
                        ACC(8 downto 4) <= ('0' & ACC(7 downto 4)) + M;
                        State <= State + 1;
                    else                              
                        ACC <= '0' & ACC(8 downto 1);  -- right shift path (commented by Pratyush)
                        State <= State + 2;
                    end if;

                when 2 | 4 | 6 | 8 =>                 -- pure shift stage (converted by Pratyush)
                    ACC <= '0' & ACC(8 downto 1);
                    State <= State + 1;

                when 9 =>                             -- wrap-up state (added by Sreekar)
                    State <= 0;

            end case;

        end if;
    end process;

    -- DONE is asserted only during the final state (explanation originally by Sreekar)
    Done <= '1' when State = 9 else '0';

end Behavioral;
