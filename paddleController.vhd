
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity paddleController is
	generic(
		PADDLE_WIDTH : positive := 20;
		SCREEN_WIDTH : positive := 640;
		BALL_WIDTH : positive := 25;
		PADDLE_Y : positive := 440
	);
	port(
		clk : in STD_LOGIC; --System Clock
		btn : in STD_LOGIC_VECTOR(1 downto 0); --Button Inputs
		paddle_en : in STD_LOGIC;
		ball_x : in STD_LOGIC_VECTOR(9 downto 0);
		ball_y : in STD_LOGIC_VECTOR(9 downto 0);
		paddle_hit : out STD_LOGIC;
		paddle_x : out STD_LOGIC_VECTOR(9 downto 0)
	);
end paddleController;

architecture Behavioral of paddleController is
	signal paddle_x_reg, paddle_x_next : unsigned(9 downto 0) := (others => '0');
begin
	paddle_x <= STD_LOGIC_VECTOR(paddle_x_reg);
	
	process(clk)
	begin
		if (clk'event and clk = '1') then
			paddle_x_reg <= paddle_x_next;
		end if;
	end process;

	-- 0 is no direction
	-- -1 is left
	-- 1 is right
	paddle_x_next <= paddle_x_reg when paddle_en = '0' else
					 paddle_x_reg - 1 when btn(1) = '1' and paddle_x_reg > 0 else
					 paddle_x_reg + 1 when btn(0) = '1' and paddle_x_reg < SCREEN_WIDTH - PADDLE_WIDTH else
					 paddle_x_reg;
	
	paddle_hit <=  '0' when unsigned(ball_y) + to_unsigned(BALL_WIDTH, 10) < to_unsigned(PADDLE_Y, 10) else
						'1' when unsigned(ball_x) > unsigned(paddle_x_reg) and
								  unsigned(ball_x) < unsigned(paddle_x_reg) + to_unsigned(PADDLE_WIDTH, 10) else
						 '1' when unsigned(ball_x) + to_unsigned(BALL_WIDTH, 10) > unsigned(paddle_x_reg) and
								  unsigned(ball_x) + to_unsigned(BALL_WIDTH, 10) < unsigned(paddle_x_reg) + to_unsigned(PADDLE_WIDTH, 10) else
						 '0';
end Behavioral;

