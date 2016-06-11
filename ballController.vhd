
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity ballController is
	generic(
			BALL_WIDTH : positive := 25;
			BALL_START_X : positive := 300;
			BALL_START_Y : positive := 200
	);
	port(
		clk : in STD_LOGIC; --System Clock
		rst: in std_logic;
		ball_enable : in STD_LOGIC;
		block_hit : in STD_LOGIC;
		paddle_hit : in STD_LOGIC;
		x_location : out STD_LOGIC_VECTOR(9 downto 0);
		y_location : out STD_LOGIC_VECTOR(9 downto 0);
		floor_hit : out std_logic
	);
end ballController;

architecture Behavioral of ballController is	
	signal ball_x, ball_x_next : UNSIGNED(9 downto 0) := to_unsigned(BALL_START_X, 10);
	signal ball_y, ball_y_next : UNSIGNED(9 downto 0) := to_unsigned(BALL_START_Y, 10);
	signal direction_x, direction_x_next : STD_LOGIC := '1';
	signal direction_y_next, direction_y : STD_LOGIC := '0';
	signal floor_hit_sig : STD_LOGIC;
begin
		x_location <= STD_LOGIC_VECTOR(ball_x);
		y_location <= STD_LOGIC_VECTOR(ball_y);
		
		--ball register
		process(clk)
		begin
			if (clk'event and clk ='1') then
				ball_x <= ball_x_next;
				ball_y <= ball_y_next;
				direction_x <= direction_x_next;
				direction_y <= direction_y_next;
			end if;
		end process;
		
		--640X480
		--next state logic
		ball_x_next <= to_unsigned(BALL_START_X, 10) when floor_hit_sig = '1' or rst = '1' else
							ball_x when ball_enable = '0' else
							ball_x+1 when direction_x = '0' else
							ball_x-1;
		ball_y_next <= to_unsigned(BALL_START_Y, 10) when floor_hit_sig = '1' or rst = '1' else
							ball_y when ball_enable = '0' else
							ball_y+1 when direction_y = '0' else
							ball_y-1;
		direction_x_next <= '1' when ball_x+ball_width >= 638 else
									'0' when ball_x <= 1 else
									direction_x;
		direction_y_next <=  '1' when (ball_y+ball_width) >= 478 else
								   '0' when block_hit = '1' else
									'0' when ball_y <= 1 else
									'1' when paddle_hit = '1' else
									direction_y;
		floor_hit_sig <= '1' when (ball_y+ball_width) >= 478 and ball_enable = '1' else '0';
		floor_hit <= floor_hit_sig;
		
end Behavioral;

