pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
	width = 22
	height = 20
	widthscale = 1
	heightscale = 1

	spritesheet_start_x = 0
	spritesheet_start_y = 34
	mem = 0

	mouse = {
		x = 0,
		y = 0
	}

	cell = {
		spritesheet_x = 0,
		spritesheet_y = 8,
		width = 17,
		height = 17
	}

  curr_mouse_to_cell_coords = nil
  curr_mouse_to_cell = nil

	cells = {}
	gems = {}

  gamestate = "player1"
  colorchoice = 0
  p1choice1 = nil
  p1choice2 = nil
  p2choice1 = nil
  p2choice2 = nil


  --board setup
  -- -1 means the cell is off the board
  --  0 means the cell is empty
  --  1 is player1 color1
  --  2 is player1 color2
  --  3 is player2 color1
  --  4 is player2 color2
  board = {}
  for i = 1, 7 do
    board[i] = {}
    for j = 1, 7 do
      if ((i + j < 5) or (i + j > 11)) then
        board[i][j] = -1
      else
        board[i][j] = 0
      end
    end
  end

 -- board[3][3] = 2
  --board[3][4] = 3
  --board[2][4] = 1
  --board[1][4] = 4

  --left to right, top to bottom
  cell_coords = {
    {32,22},
    {48,22},
    {64,22},
    {80,22},

    {24,33},
    {40,33},
    {56,33},
    {72,33},
    {88,33},

    {16,44},
    {32,44},
    {48,44},
    {64,44},
    {80,44},
    {96,44},

    {8,55},
    {24,55},
    {40,55},
    {56,55},
    {72,55},
    {88,55},
    {104,55},

    {16,66},
    {32,66},
    {48,66},
    {64,66},
    {80,66},
    {96,66},

    {24,77},
    {40,77},
    {56,77},
    {72,77},
    {88,77},

    {32,88},
    {48,88},
    {64,88},
    {80,88},
  }

	keys={}

  mouse_pixels = {}

function _init()
	init_keys()
	mouse_init()
	cells_init()
end

function _update60()
	upd_keys()
  mouse_update()

  cells_update()
  game_update()



	
	
end

function _draw()
  --draw background
	rectfill(0,0,127,127,12)

  cells_draw()

  --print coordinates of cell under mouse
  if (curr_mouse_to_cell != nil) then 
    print(curr_mouse_to_cell[1], 0, 8, 7)
    print(curr_mouse_to_cell[2], 8, 8, 7)
  end

  text_draw()
	--gems_draw()
	mouse_draw()


  print(mouse.x, 0, 0, 7)
  print(mouse.y, 16, 0, 7)

end

function mouse_init() 
	--enable mouse support
	poke(0x5f2d, 1)

	for sx = 8, 11 do
		for sy = 0, 5 do
			if (sget(sx, sy) == 7) then
				add(mouse_pixels, {sx - 8, sy})
			end
		end
	end
end

function mouse_update()
	mouse.x = stat(32)
	mouse.y = stat(33)
  curr_mouse_to_cell = mouse_to_cell()
  curr_mouse_to_cell_coords = mouse_to_cell_coords()
end

function mouse_draw()
	for v in all(mouse_pixels) do
		local x = mouse.x + v[1]
		local y = mouse.y + v[2]
		pset(x, y, inverses_dark[pget(x, y) + 1])
	end
end	

function game_update()
  if (gamestate == "player1") then
    if (is_pressed(4)) colorchoice = 1
    if (is_pressed(5)) colorchoice = 2

    --check whether a piece should be put down
    if (is_pressed(6)) then
      if (curr_mouse_to_cell != nil and board[curr_mouse_to_cell[1]][curr_mouse_to_cell[2]] == 0)  then
        if ((p1choice1 == nil and colorchoice == 1) or (p1choice2 == nil and colorchoice == 2)) then --put a piece down!
          board[curr_mouse_to_cell[1]][curr_mouse_to_cell[2]] = colorchoice
          if (colorchoice == 1) then 
            p1choice1 = curr_mouse_to_cell
          elseif (colorchoice == 2) then
            p1choice2 = curr_mouse_to_cell
          end
        end
      end
    end

    --check whether the player is trying to delete their pieces (lshift)
    if (btn(4, 1)) then
      if (p1choice1 != nil) then
        board[p1choice1[1]][p1choice1[2]] = 0
        p1choice1 = nil
      end
      if (p1choice2 != nil) then
        board[p1choice2[1]][p1choice2[2]] = 0
        p1choice2 = nil
      end      
    end

    --check whether the player wants to end their turn
    if (btnp(5,1)) then
        gamestate = "p1top2"
        p1choice1 = nil
        p1choice2 = nil
        colorchoice = 0
    end
  end

  if (gamestate == "player2") then
    if (is_pressed(4)) colorchoice = 3
    if (is_pressed(5)) colorchoice = 4

    --check whether a piece should be put down
    if (is_pressed(6)) then
      if (curr_mouse_to_cell != nil and board[curr_mouse_to_cell[1]][curr_mouse_to_cell[2]] == 0)  then
        if ((p2choice3 == nil and colorchoice == 3) or (p2choice4 == nil and colorchoice == 4)) then --put a piece down!
          board[curr_mouse_to_cell[1]][curr_mouse_to_cell[2]] = colorchoice
          if (colorchoice == 3) then 
            p2choice3 = curr_mouse_to_cell
          elseif (colorchoice == 4) then
            p2choice4 = curr_mouse_to_cell
          end
        end
      end
    end

    --check whether the player is trying to delete their pieces (lshift)
    if (btn(4, 1)) then
      if (p2choice3 != nil) then
        board[p2choice3[1]][p2choice3[2]] = 0
        p2choice3 = nil
      end
      if (p2choice4 != nil) then
        board[p2choice4[1]][p2choice4[2]] = 0
        p2choice4 = nil
      end      
    end

    --check whether the player wants to end their turn
    if (btnp(5,1)) then
        gamestate = "p2top1"
        p2choice3 = nil
        p2choice4 = nil
        colorchoice = 0
    end
  end

  if (gamestate == "p1top2") then
    gamestate = "player2"
  end

  if (gamestate == "p2top1") then
    gamestate = "player1"
  end
end




--each cell has an x and y coordinate, as well as an index into the cell_coords table (this holds where that cell is "supposed" to be)
function cell_create(px, py, pindex)
	return {x = px, y = py, index = pindex}
end

function cells_init()
  for i = 1, 37 do
    add(cells, cell_create(cell_coords[i][1], cell_coords[i][2] - 0.01), i) --the -0.01 is cheating a bit, lol
  end
end

function cells_update()
  --lerp all cells towards their default location
  i = 1
  for value in all(cells) do
   value.y = lerp(value.y, cell_coords[i][2] - .9, 0.06)
   i+=1
  end
  
  --lerp the cell under the mouse upward
  closestcell = curr_mouse_to_cell_coords
  if (closestcell == nil) return
  --if there is a tile there, don't lerp upward
  local index = index_to_board_coords(closestcell)
  if (board[index[1]][index[2]] != 0) return
  cells[closestcell].y = lerp(cells[closestcell].y, cell_coords[closestcell][2] - 6, 0.04)

  --push the cell downward when you click
  if (is_pressed(6)) then
    --cells[closestcell].y = lerp(cells[closestcell].y, cell_coords[closestcell][2] + 20, 0.05)
    cells[closestcell].y = cell_coords[closestcell][2] + 4
  end
end

function cells_draw()
  palt(0, false)
  palt(15, true)

  local board_index = 1
	for v in all(cells) do
    rectfill(v.x + 1, v.y + 13, v.x + 7, 127, 6)
    rectfill(v.x + 9, v.y + 13, v.x + 15, 127, 5)
    line(v.x, v.y + 12, v.x, 127, 0)
    line(v.x + 8, v.y + 15, v.x + 8, 127, 0)
    line(v.x + 16, v.y + 12, v.x + 16, 127, 0)
		sspr(cell.spritesheet_x, cell.spritesheet_y, cell.width, cell.height, v.x, v.y, cell.width, cell.height) --draw the actual empty cell

    local coords = index_to_board_coords(board_index)  
    if (board[coords[1]][coords[2]] == 1) then --draw tokens
      spr(5, v.x + 1, v.y + 2, 2, 2)
    elseif (board[coords[1]][coords[2]] == 2) then
      spr(7, v.x + 1, v.y + 2, 2, 2)
    elseif (board[coords[1]][coords[2]] == 3) then
      spr(9, v.x + 1, v.y + 2, 2, 2)
    elseif (board[coords[1]][coords[2]] == 4) then
      spr(11, v.x + 1, v.y + 2, 2, 2)
    end

    --todo: fix this trash
    --draw an icon indicating the color tile that will be put in this cell if you click
    local curcell = curr_mouse_to_cell
    if (curcell != nil and board[curcell[1]][curcell[2]] == 0 and (currcell == index_to_board_coords(board_index))) then
      circfill(v.x + 8, v.y + 8, 1, colorchoice_to_color(colorchoice))
    end



    board_index += 1
	end
  palt()

end

function gems_update()
	gem_coords = curr_mouse_to_cell_coords
	if (is_pressed(6)) then

		sfx(0)
		add(gems, gem_coords)
	end
end

function gems_draw()
	for v in all(gems) do
		sspr(2 * 8, 0, 10, 8, v.x, v.y, 10 * 2, 8 * 2)
	end
end


function text_draw()
    if (gamestate == "player1") then
        print("player 1's turn", 35, 8, 7)
    elseif (gamestate == "player2") then
        print("player 2's turn", 35, 8, 7)
    end
end

--returns the index of the closest cell to the mouse
--should be called after the blank cells are drawn
--[[
function mouse_to_cell_original()
  if (pget(mouse.x, mouse.y) != 7) return nil
  index = 1
  closestindex = 1
	d = dist(mouse.x, mouse.y, cells[1].x + cell.width / 2, cells[1].y + cell.height / 2)
	for v in all (cells) do
		if (dist(mouse.x, mouse.y, v.x + cell.width / 2, v.y + cell.height / 2) < d) then
			d = dist(mouse.x, mouse.y, v.x + cell.width / 2, v.y + cell.height / 2)
      closestindex = index
		end
    index += 1
	end

	return closestindex
end
]]

--returns the index of the closest cell to the mouse
function mouse_to_cell_coords()
  local h = 64
  local k = 60
  local a = 54
  local b = 42
  if (mouse.y > sqrt((1 - ((mouse.x - h)^2) / (a ^ 2)) * (b ^ 2)) + k) return nil
  if (mouse.y < (-1 * sqrt((1 - ((mouse.x - h)^2) / (a ^ 2)) * (b ^ 2)) + k)) return nil

  index = 1
  closestindex = 1
  d = dist(mouse.x, mouse.y, cell_coords[index][1] + cell.width / 2, cell_coords[index][2] + cell.height / 2)
  for v in all (cell_coords) do
    if (dist(mouse.x, mouse.y, cell_coords[index][1] + cell.width / 2, cell_coords[index][2] + cell.height / 2) < d) then
      d = dist(mouse.x, mouse.y, cell_coords[index][1] + cell.width / 2, cell_coords[index][2] + cell.height / 2)
      closestindex = index
    end
    index += 1
  end

  return closestindex
end


--returns the indices into the board table of the cell under the mouse 
--returns coords as a table {i,j}
function mouse_to_cell()
  local coords_index = mouse_to_cell_coords()
  if (coords_index == nil) return nil
  return index_to_board_coords(coords_index)
end

--helper function for mouse_to_cell()
--takes an index i, where 1 is the topleft most hex, 2 is to the right of that, etc
--returns coords as a table {i,j}
function index_to_board_coords(index)
  local counter = 0
  for i = 1, 7 do
    for j = 1, 7 do
      if (board[i][j] != -1) then
        counter += 1
        if (counter == index) return {i, j}
      end
    end
  end
end

function colorchoice_to_color(c)
  if (c == 1) return 9
  if (c == 2) return 8
  if (c == 3) return 11
  if (c == 4) return 13
end


function dist(x1,y1, x2,y2) return sqrt((x2-x1)^2+(y2-y1)^2) end

--keyboard handler--
--left mouse is 6
function is_held(k) return band(keys[k], 1) == 1 end
function is_pressed(k) return band(keys[k], 2) == 2 end
function is_released(k) return band(keys[k], 4) == 4 end

function upd_key(k)
	if (k == 6) then
		if keys[k] == 0 then
			if (stat(34) == 1) then keys[k] = 3 end
		elseif keys[k] == 1 then
			if (stat(34) != 1) then keys[k] = 4 end
		elseif keys[k] == 3 then
			if (stat(34) ==1) then keys[k] = 1
			else keys[k] = 4 end
		elseif keys[k] == 4 then
			if (stat(34) == 1) then keys[k] = 3
			else keys[k] = 0 end
		end		
	else 
		if keys[k] == 0 then
			if btn(k) then keys[k] = 3 end
		elseif keys[k] == 1 then
			if btn(k) == false then keys[k] = 4 end
		elseif keys[k] == 3 then
			if btn(k) then keys[k] = 1
			else keys[k] = 4 end
		elseif keys[k] == 4 then
			if btn(k) then keys[k] = 3
			else keys[k] = 0 end
		end
	end
end

function init_keys()
	for a = 0,6 do keys[a] = 0 end
end

function upd_keys()
	for a = 0,6 do upd_key(a) end
end

function lerp(a,b,t) 
  --return a+(b-a)*t 
  return (b - a) * (-2^(-10 * t) + 1 ) + a
end

inverses_dark = {
	6,
	9,
	13,
	9,
	13,
	13,
	2,
	0,
	13,
	1,
	1,
	9,
	2,
	2,
	4,
	1
}

inverses = {
	{0,7},
	{1,15},
	{2,12},
	{3,14},
	{4,12},
	{5,6},
	{6,5},
	{7,0},
	{8,12},
	{9,1},
	{10,1},
	{11,14},
	{12,4},
	{13,5},
	{14,3},
	{15,1}
}

__gfx__
0000000070000000000000000000000006000000fffff99999fffffffffff88888fffffffffffbbbbbfffffffffffdddddffffff000000000000000000000000
0000000077000000000088800000000006000000fff999999999fffffff888888888fffffffbbbbbbbbbfffffffdddddddddffff000000000000000000000000
0070070077700000008888888000000006000000ff99999999999fffff88888888888fffffbbbbbbbbbbbfffffdddddddddddfff000000000000000000000000
0007700077770000088e88888200000006000000999999999999999f888888888888888fbbbbbbbbbbbbbbbfdddddddddddddddf000000000000000000000000
0007700000700000088888882200000006000000999999999999999f888888888888888fbbbbbbbbbbbbbbbfdddddddddddddddf000000000000000000000000
0070070000070000088888882200000006000000999999999999999f888888888888888fbbbbbbbbbbbbbbbfdddddddddddddddf000000000000000000000000
00000000000000000088888220000000e6000000999999999999999f888888888888888fbbbbbbbbbbbbbbbfdddddddddddddddf000000000000000000000000
00000000000000000000222000000000e6000000999999999999999f888888888888888fbbbbbbbbbbbbbbbfdddddddddddddddf000000000000000000000000
ffffffffffffffffffffffffffffffff06000000999999999999999f888888888888888fbbbbbbbbbbbbbbbfdddddddddddddddf000000000000000000000000
ffffff00000ffffffffffffff75fffff06000000449999999999944f228888888888822f33bbbbbbbbbbb33f11ddddddddddd11f000000000000000000000000
ffff007777700ffffffffffff775ffff06000000ff49999999994fffff28888888882fffff3bbbbbbbbb3fffff1ddddddddd1fff000000000000000000000000
fff07777777770fffffffffff7775fff06000000fff449999944fffffff228888822fffffff33bbbbb33fffffff11ddddd11ffff000000000000000000000000
f007777777777700fffffffff77775ff06000000fffff44444fffffffffff22222fffffffffff33333fffffffffff11111ffffff000000000000000000000000
07777777777777770ffffffff5575fff06000000ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff000000000000000000000000
07777777777777770ffffffffff575ff06000000ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff000000000000000000000000
07777777777777770fffffffffff5fff06000000ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff000000000000000000000000
07777777777777770ffffffff0000000060000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
07777777777777770fffffffffffffffe60000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
07777777777777770fffffffffffffffe60000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
07777777777777770fffffffffffffff060000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
f007777777777700ffffffffffffffff060000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
fff07777777770ffffffffffffffffff060000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ffff007777700fffffffffffffffffff060000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ffffff00000fffffffffffffffffffff060000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ffffffffffffffffffffffffffffffff060000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ffffffffffffffffffffffffffffffff666666660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ffffffffffffffffffffffffffffffff060000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ffffffffffffffffffffffffffffffff060000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ffffffffffffffffffffffffffffffff06a00a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ffffffffffffffffffffffffffffffff060aa0aa0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ffffffffffffffffffffffffffffffff060000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ffffffffffffffffffffffffffffffff060000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ffffffffffffffffffffffffffffffff000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ffffffffffffffffffffffffffffffff000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ffffffffffffffffffffffffffffffff000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ffffffffffffffffffffffffffffffff000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ffffffffffffffffffffffffffffffff000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ffffffffffffffffffffffffffffffff000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ffffffffffffffffffffffffffffffff000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ffffffffffffffffffffffffffffffff000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
000100000962005010006000060000600006000060000600226000060025600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600
