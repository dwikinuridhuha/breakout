library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity breakout_top is
	generic(
			CLK_RATE: natural := 50_000_000;
			DEBOUNCE_RATE: natural := 100;
			PADDLE_WIDTH : positive := 125;
			PADDLE_Y : positive := 450;
			SCREEN_WIDTH : positive := 640;
			PADDLE_COLOR: STD_LOGIC_VECTOR := "00000011"
		);
	port(clk : in  STD_LOGIC;
			btn : in  STD_LOGIC_VECTOR(3 downto 0);
			seg : out  STD_LOGIC_VECTOR (6 downto 0);
			dp : out  STD_LOGIC;
			an : out  STD_LOGIC_VECTOR (3 downto 0);
			Hsync : out STD_LOGIC;
			Vsync : out STD_LOGIC;
			vgaRed : out STD_LOGIC_VECTOR(2 downto 0);
			vgaGreen : out STD_LOGIC_VECTOR(2 downto 0);
			vgaBlue : out STD_LOGIC_VECTOR(1 downto 0);
			MemAdr : out Std_Logic_Vector(22 downto 0); -- The address pins to the memory device
			MemOE : out Std_Logic; -- : Output enable pin to memory device
			MemWR : out Std_Logic; -- Write enable pin to memory device
			RamCS : out Std_Logic; -- Memory chip select
			RamLB : out Std_Logic; -- Memory ˜lower byte control signal
			RamUB : out Std_Logic; -- Memory ˜upper byte control signal
			RamCLK : out Std_Logic; -- Memory CLK signal
			RamADV : out Std_Logic; -- Memory ADV signal
			RamCRE : out Std_Logic; -- Memory CRE signal
			MemDB : inout Std_Logic_Vector(15 downto 0)
	);
		
end breakout_top;

architecture arch of breakout_top is

	function log2c(n: integer) return integer is
		variable m, p: integer;
	begin
		m := 0;
		p := 1;
		while p < n loop
			m := m + 1;
			p := p * 2;
		end loop;
		return m;
	end log2c;


	-- debouncing constants/signals
	constant DEBOUNCE_MAX : Natural := CLK_RATE / DEBOUNCE_RATE;
	constant DEBOUNCE_BITS : Natural := log2c(DEBOUNCE_MAX);
	signal timer_reg, timer_next : unsigned(DEBOUNCE_BITS-1 downto 0) := (others => '0');
	signal btn_en: std_logic;
	signal de_btn: std_logic_vector(3 downto 0);

	-- VGA controller signals
	signal pixel_x : STD_LOGIC_VECTOR(9 downto 0);
	signal pixel_y : STD_LOGIC_VECTOR(9 downto 0);
	signal last_column : STD_LOGIC;
	signal last_row : STD_LOGIC;
	signal blank : STD_LOGIC;
	
	-- Ball + Paddle Controller signals
	constant BALL_WIDTH : positive := 25;
	signal frame_done : STD_LOGIC;
	signal rgb_out, block_rgb: std_logic_vector(7 downto 0);
	signal ball_x, ball_y : STD_LOGIC_VECTOR(9 downto 0);
	signal paddle_x: std_logic_vector(9 downto 0);
	signal background_rgb : std_logic_vector(7 downto 0);
	signal ball_disp, paddle_disp : std_logic;
	signal block_disp: std_logic;
	signal btn_paddle: std_logic_vector(1 downto 0);
	signal paddle_hit : STD_LOGIC;
	signal block_hit : STD_LOGIC;
	signal ball_enable : std_logic;

	-- sev segment signals
	signal score_out: std_logic_vector(15 downto 0) := (others => '0');
	signal score0_reg, score0_next, score1_reg, score1_next: std_logic_vector(3 downto 0):= (others => '0');

	-- framebuffer signals
	signal picture_out : std_logic_vector(7 downto 0);
	signal pic_disp, pic_disp_next : std_logic := '1';
	signal image_sel : std_logic_vector(4 downto 0);
	
	-- delay logic
	constant read_cycles : positive := 4;
	signal hs_delay, vs_delay : Std_Logic_Vector(read_cycles - 1 downto 0) := (others => '0');
	signal blank_delay : Std_Logic_Vector(read_cycles - 1 downto 0) := (others => '1');
	signal hs, vs : Std_Logic;
	signal blank_in : Std_Logic;
	
	--win/lose logic
	signal win_reg, win_next, lose_reg, lose_next : std_logic := '0';
	signal menu_reg, menu_next : std_logic := '0';
	constant win_count : positive := 30;
	signal life_reg, life_next : unsigned(3 downto 0) := "0011";
	signal floor_hit : std_logic;
	signal score_rollover: std_logic := '0';
begin
	btn_paddle <= de_btn(1 downto 0);
-- registers
process(clk)
begin
	if (clk'event and clk = '1') then
		score0_reg <= score0_next;
		score1_reg <= score1_next;
		pic_disp <= pic_disp_next;
		menu_reg <= menu_next;
		win_reg <= win_next;
		lose_reg <= lose_next;
		life_reg <= life_next;
		timer_reg <= timer_next;

		if (blank = '1') then
			vgaRed <= "000";
			vgaGreen <= "000";
			vgaBlue <= "00";
		else
			vgaRed <= rgb_out(7 downto 5);
			vgaGreen <= rgb_out(4 downto 2);
			vgaBlue <= rgb_out(1 downto 0);
		end if;
	end if;
end process;

	score_rollover <= '1' when score0_reg = "1001" else
						  '0';
							
	score0_next <= "0000" when btn(3) = '1' else
						std_logic_vector(unsigned(score0_reg) + 1) when block_hit = '1' and unsigned(score0_reg) < "1001"	else
						"0000"  when block_hit = '1' and score0_reg = "1001" else
					   score0_reg;
	
	score1_next <= "0000" when btn(3) = '1' else
					std_logic_vector(unsigned(score1_reg) + 1) when block_hit = '1' and score_rollover = '1' else
					score1_reg;
					
	-- output
	score_out <= std_logic_vector(life_reg) & "0000" & score1_reg & score0_reg;

	background_rgb <= "11111111"; -- background color is white
	
	frame_done <= last_column and last_row;
	
	
	ball_disp <= '1' when unsigned(pixel_x) > unsigned(ball_x) and unsigned(pixel_x) < unsigned(ball_x) + to_unsigned(ball_width, 10) and
								unsigned(pixel_y) > unsigned(ball_y) and unsigned(pixel_y) < unsigned(ball_y) + to_unsigned(ball_width, 10) else
								'0';
								
	paddle_disp <= '1' when unsigned(pixel_x) > unsigned(paddle_x) and unsigned(pixel_x) < unsigned(paddle_x) + to_unsigned(paddle_width, 10) and
							 unsigned(pixel_y) > PADDLE_Y and unsigned(pixel_y) < to_unsigned(PADDLE_Y, 10) + 20 else
							'0';
							
	-- Color Muxing
	rgb_out <= picture_out when pic_disp = '1' else
			"00000000" when ball_disp = '1' else
			PADDLE_COLOR when paddle_disp = '1' else
			block_rgb when block_disp = '1' else
				background_rgb;
	
	
	pic_disp_next <= '1' when menu_reg = '0' else
					 '1' when win_reg = '1' else
					 '1' when lose_reg = '1' else
					 '0';
	
	menu_next <= '0' when btn(3) = '1' else '1' when btn(2) = '1' else menu_reg;
	
	win_next <= '0' when btn(3) = '1' else '1' when score_out(7 downto 0) = "0011" & "0000" else win_reg;
	
	lose_next <= '0' when btn(3) = '1' else '1' when life_reg = "0000" else lose_reg;
	
	life_next <= "0011" when btn(3) = '1' else life_reg - 1 when floor_hit = '1' else life_reg;
	
	image_sel <= "00000" when menu_reg = '0' else
			 "00001" when lose_reg = '1' else
			 "00010" when win_reg = '1' else
			 "00011";
	
	-- VGA delay logic
	process(clk, btn(3))
	begin
		if (btn(3) = '1') then
			hs_delay <= (others => '0');
			vs_delay <= (others => '0');
			blank_delay <= (others => '1');
		elsif (clk'event and clk = '1') then
			hs_delay(0) <= hs;
			vs_delay(0) <= vs;
			blank_delay(0) <= blank_in;
			for i in 1 to read_cycles - 1 loop
				hs_delay(i) <= hs_delay(i-1);
				vs_delay(i) <= vs_delay(i-1);
				blank_delay(i) <= blank_delay(i-1);
			end loop;
		end if;
	end process;
	
	Hsync <= hs_delay(hs_delay'high);
	Vsync <= vs_delay(vs_delay'high);
	blank <= blank_delay(blank_delay'high);
	
	
	-- debouncing next states
	timer_next <= timer_reg + 1 when timer_reg < DEBOUNCE_MAX else
					  (others => '0');
					  
	btn_en <= '1' when timer_reg = DEBOUNCE_MAX else
				 '0';


process(clk,btn_en)
begin
	if (clk'event AND clk = '1') then
		if(btn_en = '1') then
			de_btn <= btn;
		end if;
	end if;
end process;
	
-------------------
-- Instantiations--
-------------------
		
-- VGA Controller
	vga_ctrl : entity work.vga_alt(arch)
		port map(
			clk => clk,
			rst => btn(3),
			HS => hs,
			VS => vs,
			pixel_x => pixel_x,
			pixel_y => pixel_y,
			last_column => last_column,
			last_row => last_row,
			blank => blank_in
		);		
		
		
	-- Ball Controller
	ball0 : entity work.ballController(Behavioral)
		generic map(
			BALL_WIDTH => BALL_WIDTH
			)
		port map(
				clk => clk,
				rst => btn(3),
				ball_enable => ball_enable,
				block_hit => block_hit,
				paddle_hit => paddle_hit,
				x_location => ball_x,
				y_location => ball_y,
				floor_hit => floor_hit
			);
	ball_enable <= frame_done and (not pic_disp) and (not win_reg) and (not lose_reg);	
	
	-- Paddle Controller
	paddle : entity work.paddleController(Behavioral)
	generic map(
		PADDLE_WIDTH => PADDLE_WIDTH,
		SCREEN_WIDTH => SCREEN_WIDTH,
		BALL_WIDTH => BALL_WIDTH,
		PADDLE_Y => PADDLE_Y
	)
	port map(
		clk => clk,
		btn => btn_paddle,
		paddle_en => frame_done,
		ball_x => ball_x,
		ball_y => ball_y,
		paddle_hit => paddle_hit,
		paddle_x => paddle_x
	);
		
		
	-- Block Controller	
		block_control : entity work.blocks(Behavioral)
	port map(
		clk => clk, rst => btn(3), pixel_x=> pixel_x, pixel_y=> pixel_y, ball_x => ball_x, ball_y => ball_y,
		block_hit => block_hit, block_rgb => block_rgb, block_disp => block_disp
	);
	
	

-- instantiate sev_seg_controller
sev_seg_ctrl: entity work.seven_segment_control(segment_arch)
		port map (clk=>clk, data_in=>score_out, dp_in=>"1000",
					blank=>"0000", seg=>seg, dp=>dp, an=>an);

-- instantiate image controller
	buffer0 : entity work.framebuffer(Behavioral)
		port map (
			clk => clk,
			rst => btn(3),
			image => image_sel,
			pixel_x => pixel_x,
			pixel_y => pixel_y,
			blank => blank_in,
			picture => picture_out,
			MemAdr => MemADR,
			MemOE => MemOE,
			MemWR => MemWR,
			RamCS => RamCS,
			RamLB => RamLB,
			RamUB => RamUB,
			RamCLK => RamCLK,
			RamADV => RamADV,
			RamCRE => RamCRE,
			MemDB => MemDB
		);

end arch;