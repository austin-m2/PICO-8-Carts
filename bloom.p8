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

  controlstate = "mouse"
  is_online_mode_enabled = true

  gamestate = "player1"
  colorchoice = 0
  p1choice1 = nil
  p1choice2 = nil
  p2choice1 = nil
  p2choice2 = nil
  p1score = 0
  p2score = 0
  maxscore = 15


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
  columns_init()
  buttons_init()

  gamestate = "turn1"
end

function _update60()
	upd_keys()
  mouse_update()

  cells_update()
  game_update()
  columns_update()
  buttons_update()



	
	
end

function _draw()
  --draw background
	rectfill(0,0,127,127,12)


  columns_draw()
  cells_draw()
  buttons_draw()

  --print coordinates of cell under mouse
--[[
  if (curr_mouse_to_cell != nil) then 
    print(curr_mouse_to_cell[1], 0, 8, 7)
    print(curr_mouse_to_cell[2], 8, 8, 7)
  end
]]
  text_draw()
	--gems_draw()
	mouse_draw()


  --print(mouse.x, 0, 0, 7)
  --print(mouse.y, 16, 0, 7)


  if (gamestate == "end") then
    if (p1score > p2score) then
      print("player 1 wins~!", 36, 8, 7)
    else
      print("player 2 wins~!", 36, 8, 7)
    end
  end



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
  if (is_pressed(0) or is_pressed(1) or is_pressed(2) or (is_pressed(3))) controlstate = "keyboard"
  if (is_pressed(6)) controlstate = "mouse"

  if (controlstate == "mouse") then
    mouse.x = stat(32)
    mouse.y = stat(33)
  else
    if (is_held(0)) mouse.x -= 1.5
    if (is_held(1)) mouse.x += 1.5
    if (is_held(2)) mouse.y -= 1.5
    if (is_held(3)) mouse.y += 1.5
  end


  curr_mouse_to_cell = mouse_to_cell()
  curr_mouse_to_cell_coords = mouse_to_cell_coords()
end

function mouse_draw()
--[[
	for v in all(mouse_pixels) do
		local x = mouse.x + v[1]
		local y = mouse.y + v[2]
		pset(x, y, inverses_dark[pget(x, y) + 1])
	end
]]
palt(0, false)
palt(15, true)
spr(51, mouse.x, mouse.y)
end	

function game_update()

  if (gamestate == "turn1") then
    --check if player is choosing a color
    --if (is_pressed(4)) colorchoice = 1
    --if (is_pressed(5)) colorchoice = 2
    if (is_pressed(6) and dist(mouse.x, mouse.y, left_column_pos[1] + 8, left_column_pos[2] + 8) < 7.5) then
      if (p1choice1 == nil and mouse.x < left_column_pos[1] + 8) then 
        colorchoice = 2
        left_column_pos[2] += 3
      end 
      if (p1choice2 == nil and mouse.x > left_column_pos[1] + 8) then 
        colorchoice = 1
        left_column_pos[2] += 3
      end

    --check whether a piece should be put down
    elseif (is_pressed(6)) then
      if (curr_mouse_to_cell != nil and board[curr_mouse_to_cell[1]][curr_mouse_to_cell[2]] == 0)  then
        if ((p1choice1 == nil and p1choice2 == nil and colorchoice == 1) or (p1choice1 == nil and p1choice2 == nil and colorchoice == 2)) then --put a piece down!
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
    if (is_pressed(6) and is_mouse_inside_button(undo_button_pos)) then
    --if (btn(4, 1)) then
      if (p1choice1 != nil) then
        board[p1choice1[1]][p1choice1[2]] = 0
        p1choice1 = nil
      end
      if (p1choice2 != nil) then
        board[p1choice2[1]][p1choice2[2]] = 0
        p1choice2 = nil
      end  
      colorchoice = 0    
    end

    --check whether the player wants to end their turn
    if (is_pressed(6) and is_mouse_inside_button(go_button_pos) and (p1choice1 != nil or p1choice2 != nil)) then
        gamestate = "p1top2"
        p1choice1 = nil
        p1choice2 = nil
        colorchoice = 0
    end
  end

--[[
    if (btnp(5,1) and (p1choice1 != nil or p1choice2 != nil)) then
        gamestate = "p1top2"
        p1choice1 = nil
        p1choice2 = nil
        colorchoice = 0
    end
  end
]]

  if (gamestate == "player1") then
    --check if player is choosing a color
    --if (is_pressed(4)) colorchoice = 1
    --if (is_pressed(5)) colorchoice = 2
    if (is_pressed(6) and dist(mouse.x, mouse.y, left_column_pos[1] + 8, left_column_pos[2] + 8) < 7.5) then
      if (p1choice2 == nil and mouse.x < left_column_pos[1] + 8) then
        colorchoice = 2
        left_column_pos[2] += 3
      end
      if (p1choice1 == nil and mouse.x > left_column_pos[1] + 8) then
        colorchoice = 1
        left_column_pos[2] += 3
      end

    --check whether a piece should be put down
    elseif (is_pressed(6)) then
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
    if (is_pressed(6) and is_mouse_inside_button(undo_button_pos)) then
    --if (btn(4, 1)) then
      if (p1choice1 != nil) then
        board[p1choice1[1]][p1choice1[2]] = 0
        p1choice1 = nil
      end
      if (p1choice2 != nil) then
        board[p1choice2[1]][p1choice2[2]] = 0
        p1choice2 = nil
      end     
      colorchoice = 0 
    end

    --check whether the player wants to end their turn
    if (is_pressed(6) and is_mouse_inside_button(go_button_pos) and (p1choice1 != nil or p1choice2 != nil)) then
    --if (btnp(5,1) and (p1choice1 != nil or p1choice2 != nil)) then
        gamestate = "p1top2"
        p1choice1 = nil
        p1choice2 = nil
        colorchoice = 0
    end
  end

  if (gamestate == "player2") then
    --check if player is choosing a color
    --if (is_pressed(4)) colorchoice = 3
    --if (is_pressed(5)) colorchoice = 4
    if (is_pressed(6) and dist(mouse.x, mouse.y, right_column_pos[1] + 8, right_column_pos[2] + 8) < 7.5) then
      if (p2choice3 == nil and mouse.x < right_column_pos[1] + 8) then
        colorchoice = 3
        right_column_pos[2] += 3
      end
      if (p1choice4 == nil and mouse.x > right_column_pos[1] + 8) then 
        colorchoice = 4
        right_column_pos[2] += 3
      end

    --check whether a piece should be put down
    elseif (is_pressed(6)) then
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
    if (is_pressed(6) and is_mouse_inside_button(undo_button_pos)) then
    --if (btn(4, 1)) then
      if (p2choice3 != nil) then
        board[p2choice3[1]][p2choice3[2]] = 0
        p2choice3 = nil
      end
      if (p2choice4 != nil) then
        board[p2choice4[1]][p2choice4[2]] = 0
        p2choice4 = nil
      end      
      colorchoice = 0
    end

    --check whether the player wants to end their turn
    if (is_pressed(6) and is_mouse_inside_button(go_button_pos) and (p2choice3 != nil or p2choice4 != nil)) then
    --if (btnp(5,1) and (p2choice3 != nil or p2choice4 != nil)) then
        gamestate = "p2top1"
        p2choice3 = nil
        p2choice4 = nil
        colorchoice = 0
    end
  end

  if (gamestate == "p1top2") then
    bloomtable = {}
    for i = 1, 7 do
      for j = 1, 7 do
        if (board[i][j] > 0)  then --a piece is here!
          --check if this piece is already in a bloom we know about
          found = false
          for bloomy in all(bloomtable) do
            for piece in all(bloomy) do
              if (piece[1] == i and piece[2] == j) then
                found = true
              end
            end
          end

          --only add enemy blooms to the table
          if ((not found) and (board[i][j] == 3 or board[i][j] == 4)) then
            bloom = {}
            findbloom(i, j, bloom)
            add(bloomtable, bloom)
          end
        end
      end
    end

    --now we have a table containing all the enemy blooms on the board!
    --check to see if any of them should be destroyed
    deadblooms = {}
    for bloom in all(bloomtable) do
     alive = false
     for piece in all(bloom) do
      if (is_there_an_empty_neighbor(piece)) then
        alive = true
        break
      end 
     end
     if (not alive) then
      --mark bloom for deletion
      add(deadblooms, bloom)
     end
    end

    --kill blooms that were marked for deletion
    for bloom in all(deadblooms) do
      for piece in all(bloom) do
        board[piece[1]][piece[2]] = 0
        cells[board_coords_to_index(piece[1], piece[2])].y = cell_coords[board_coords_to_index(piece[1], piece[2])][2] + 20
        p1score += 1
      end
    end

    if (p1score >= maxscore) then
      gamestate = "end"
    else
      gamestate = "player2"
    end
  end

  if (gamestate == "p2top1") then
    bloomtable = {}
    for i = 1, 7 do
      for j = 1, 7 do
        if (board[i][j] > 0)  then --a piece is here!
          --check if this piece is already in a bloom we know about
          found = false
          for bloomy in all(bloomtable) do
            for piece in all(bloomy) do
              if (piece[1] == i and piece[2] == j) then
                found = true
              end
            end
          end

          --only add enemy blooms to the table
          if ((not found) and (board[i][j] == 1 or board[i][j] == 2)) then
            bloom = {}
            findbloom(i, j, bloom)
            add(bloomtable, bloom)
          end
        end
      end
    end

    --now we have a table containing all the enemy blooms on the board!
    --check to see if any of them should be destroyed
    deadblooms = {}
    for bloom in all(bloomtable) do
     alive = false
     for piece in all(bloom) do
      if (is_there_an_empty_neighbor(piece)) then
        alive = true
        break
      end 
     end
     if (not alive) then
      --mark bloom for deletion
      add(deadblooms, bloom)
     end
    end

    --kill blooms that were marked for deletion
    for bloom in all(deadblooms) do
      for piece in all(bloom) do
        board[piece[1]][piece[2]] = 0
        cells[board_coords_to_index(piece[1], piece[2])].y = cell_coords[board_coords_to_index(piece[1], piece[2])][2] + 20
        p2score += 1
      end
    end

    if (p2score >= maxscore) then
      gamestate = "end"
    else
      gamestate = "player1"
    end
  end

  if (gamestate == "end")  then
    if (p1score > p2score) then
      print("player 1 wins~!", 8, 16, 7)
    else
      print("player 2 wins~!", 8, 16, 7)
    end
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

    --draw coordinate labels if online mode is on
    if (is_online_mode_enabled) then
      if (board_index == 16) then
        s_print("a", v.x + 3, v.y + 17, 5)
      elseif(board_index == 23) then
        s_print("b", v.x + 3, v.y + 17, 5)
      elseif(board_index == 29) then
        s_print("c", v.x + 3, v.y + 17, 5)
      elseif(board_index == 34) then
        s_print("d", v.x + 3, v.y + 17, 5)   
        s_print("1", v.x + 11, v.y + 17, 6)
      elseif(board_index == 35) then
        s_print("e", v.x + 3, v.y + 17, 5)   
        s_print("2", v.x + 11, v.y + 17, 6)
      elseif(board_index == 36) then
        s_print("f", v.x + 3, v.y + 17, 5)   
        s_print("3", v.x + 11, v.y + 17, 6)    
      elseif(board_index == 37) then
        s_print("g", v.x + 3, v.y + 17, 5)   
        s_print("4", v.x + 11, v.y + 17, 6)           
      elseif(board_index == 33) then  
        s_print("5", v.x + 11, v.y + 17, 6)   
      elseif(board_index == 28) then  
        s_print("6", v.x + 11, v.y + 17, 6)      
      elseif(board_index == 22) then  
        s_print("7", v.x + 11, v.y + 17, 6)                           
      end
    end


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

    --draw an icon indicating the color tile that will be put in this cell if you click
    local curcell = curr_mouse_to_cell
    if (curcell != nil and board[curcell[1]][curcell[2]] == 0 and (board_coords_to_index(curcell[1], curcell[2]) == board_index)) then
      if (gamestate == "turn1") then
        if (colorchoice != 0 and p1choice1 == nil and p1choice2 == nil) circfill(v.x + 8, v.y + 8, 1, colorchoice_to_color(colorchoice))
      elseif ((colorchoice == 1 and p1choice1 == nil) or (colorchoice == 2 and p1choice2 == nil) or (colorchoice == 3 and p2choice3 == nil) or (colorchoice == 4 and p2choice4 == nil)) then 
        circfill(v.x + 8, v.y + 8, 1, colorchoice_to_color(colorchoice))
      end
    end

    board_index += 1
	end
  palt()
end

function columns_init()
  left_column_pos = {}
  right_column_pos = {}
  left_column_orig_pos = {11, 21}
  right_column_orig_pos = {101, 21}
  left_column_pos[1] = left_column_orig_pos[1]
  left_column_pos[2] = left_column_orig_pos[2]
  right_column_pos[1] = right_column_orig_pos[1]
  right_column_pos[2] = right_column_orig_pos[2]
end

function columns_draw()
  palt(0, false)
  palt(15, true)

  --draw left column
  rectfill(left_column_pos[1] + 1, left_column_pos[2] + 10, left_column_pos[1] + 7, 127, 6)
  rectfill(left_column_pos[1] + 9, left_column_pos[2] + 13, left_column_pos[1] + 15, 127, 5)
  line(left_column_pos[1], left_column_pos[2] + 12, left_column_pos[1], 127, 0)
  line(left_column_pos[1] + 8, left_column_pos[2] + 12, left_column_pos[1] + 8, 127, 0)
  line(left_column_pos[1] + 16, left_column_pos[2] + 12, left_column_pos[1] + 16, 127, 0)
  spr(37, left_column_pos[1], left_column_pos[2], 3, 2)

  --draw right column
  rectfill(right_column_pos[1] + 1, right_column_pos[2] + 10, right_column_pos[1] + 7, 127, 6)
  rectfill(right_column_pos[1] + 9, right_column_pos[2] + 13, right_column_pos[1] + 15, 127, 5)
  line(right_column_pos[1], right_column_pos[2] + 12, right_column_pos[1], 127, 0)
  line(right_column_pos[1] + 8, right_column_pos[2] + 12, right_column_pos[1] + 8, 127, 0)
  line(right_column_pos[1] + 16, right_column_pos[2] + 12, right_column_pos[1] + 16, 127, 0)
  spr(40, right_column_pos[1], right_column_pos[2], 3, 2)


  --draw pieces on columns
  palt(0, true)
  if (gamestate == "turn1") then
    if (p1choice1 == nil and p1choice2 == nil) then
      if (colorchoice != 2) spr(13, left_column_pos[1] + 1, left_column_pos[2] + 2, 1, 2)
      if (colorchoice != 1) spr(14, left_column_pos[1] + 8, left_column_pos[2] + 2, 1, 2, true)
    end
  elseif (gamestate == "player1") then
    if (p1choice2 == nil and colorchoice != 2) spr(13, left_column_pos[1] + 1, left_column_pos[2] + 2, 1, 2)
    if (p1choice1 == nil and colorchoice != 1) spr(14, left_column_pos[1] + 8, left_column_pos[2] + 2, 1, 2, true)
  elseif (gamestate == "player2") then
    if (p2choice3 == nil and colorchoice != 3) spr(45, right_column_pos[1] + 1, right_column_pos[2] + 2, 1, 2)
    if (p2choice4 == nil and colorchoice != 4) spr(46, right_column_pos[1] + 8, right_column_pos[2] + 2, 1, 2, true)
  end

  --set color of scores depending on whose turn it is
  if (gamestate == "player1" or gamestate == "turn1") then
    p1textcol = 7
    p2textcol = 5
  elseif (gamestate == "player2") then
    p1textcol = 5
    p2textcol = 7
  end


  --draw black rectangle backdrop behind scores, then draw scores
  if (p1score < 10) then 
    rectfill(left_column_pos[1] + 6, left_column_pos[2] + 5, left_column_pos[1] + 10, left_column_pos[2] + 11, 0)
    print(p1score, left_column_pos[1] + 7, left_column_pos[2] + 6, p1textcol)
  else 
    rectfill(left_column_pos[1] + 4, left_column_pos[2] + 5, left_column_pos[1] + 12, left_column_pos[2] + 11, 0) 
    print(p1score, left_column_pos[1] + 5, left_column_pos[2] + 6, p1textcol)
  end

  if (p2score < 10) then 
    rectfill(right_column_pos[1] + 6, right_column_pos[2] + 5, right_column_pos[1] + 10, right_column_pos[2] + 11, 0)
    print(p2score, right_column_pos[1] + 7, right_column_pos[2] + 6, p2textcol)
  else 
    rectfill(right_column_pos[1] + 4, right_column_pos[2] + 5, right_column_pos[1] + 12, right_column_pos[2] + 11, 0) 
    print(p2score, right_column_pos[1] + 5, right_column_pos[2] + 6, p2textcol)
  end
end

function columns_update()
  left_column_pos[2] = lerp(left_column_pos[2], left_column_orig_pos[2] - p1score, 0.02)
  right_column_pos[2] = lerp(right_column_pos[2], right_column_orig_pos[2] - p2score, 0.02)
end

function buttons_init()
  undo_button_pos = {}
  go_button_pos = {}
  undo_button_on_pos = {35, 110}
  undo_button_off_pos = {35, 130}
  go_button_on_pos = {67, 110}
  go_button_off_pos = {67, 130}
  undo_button_pos[1] = undo_button_off_pos[1]
  undo_button_pos[2] = undo_button_off_pos[2]
  go_button_pos[1] = go_button_off_pos[1]
  go_button_pos[2] = go_button_off_pos[2]
  button_speed = 0.05
end

function buttons_update()
  if (gamestate == "turn1") then
    if (p1choice1 != nil or p1choice2 != nil) then
      undo_button_pos[2] = lerp(undo_button_pos[2], undo_button_on_pos[2], button_speed)
      go_button_pos[2] = lerp(go_button_pos[2], go_button_on_pos[2], button_speed)
    else
      undo_button_pos[2] = lerp(undo_button_pos[2], undo_button_off_pos[2], button_speed)
      go_button_pos[2] = lerp(go_button_pos[2], go_button_off_pos[2], button_speed)
    end
  else
    if (p1choice1 != nil or p1choice2 != nil or p2choice3 != nil or p2choice4 != nil) then
      undo_button_pos[2] = lerp(undo_button_pos[2], undo_button_on_pos[2], button_speed)
      go_button_pos[2] = lerp(go_button_pos[2], go_button_on_pos[2], button_speed)
    else
      undo_button_pos[2] = lerp(undo_button_pos[2], undo_button_off_pos[2], button_speed)
      go_button_pos[2] = lerp(go_button_pos[2], go_button_off_pos[2], button_speed)
    end
  end
end

function buttons_draw()
  palt(0, false)
  palt(15, true)
  if (is_mouse_inside_button(undo_button_pos)) pal(7, 10)
  sspr(0, 32, 27, 11, undo_button_pos[1], undo_button_pos[2]) --draw undo button
  pal(7, 7)
  if (is_mouse_inside_button(go_button_pos)) pal(7, 10)
  sspr(32, 32, 27, 11, go_button_pos[1], go_button_pos[2]) --draw go button
  pal()
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

    if (gamestate == "turn1") then
      bold_print("player 1's turn", 35, 6, 7)
      bold_print("place one piece!", 34, 14, 7)
    end
    if (gamestate == "player1") then
        bold_print("player 1's turn", 35, 8, 7)
    elseif (gamestate == "player2") then
        bold_print("player 2's turn", 35, 8, 7)
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

--takes a table {i, j}
--returns an index i, where 1 is the topleft most hex, 2 is to the right of that, etc
function board_coords_to_index(i, j)
  counter = 0
  for a = 1, 7 do
    for b = 1, 7 do
      if (not ((a + b < 5) or (a + b > 11))) then
        counter += 1
      end
      if (i == a and j == b) return counter
    end
  end
end


function colorchoice_to_color(c)
  if (c == 1) return 9
  if (c == 2) return 8
  if (c == 3) return 11
  if (c == 4) return 13
end


--make sure to pass in an empty table
function findbloom(i, j, bloom)
  --printh("findbloom "..i.." "..j)
  --check if piece is already in bloom
  for piece in all(bloom) do
    if (piece[1] == i and piece[2] == j) return
  end

  --piece is not already in bloom! so add it~
  add(bloom, {i, j})
  piececolor = board[i][j]

  --look for same-color pieces around this piece
  if (j > 1 and board[i][j - 1] == piececolor) findbloom(i, j - 1, bloom)
  if (i < 7 and j > 1 and board[i + 1][j - 1] == piececolor) findbloom(i + 1, j - 1, bloom)
  if (i < 7 and board[i + 1][j] == piececolor) findbloom(i + 1, j, bloom)
  if (j < 7 and board[i][j + 1] == piececolor) findbloom(i, j + 1, bloom)
  if (i > 1 and j < 7 and board[i - 1][j + 1] == piececolor) findbloom(i - 1, j + 1, bloom)
  if (i > 1 and board[i - 1][j] == piececolor) findbloom(i - 1, j, bloom)

--[[
  for piece in all(bloom) do
   printh("("..piece[1]..","..piece[2]..") ")
  end
  printh("piececolor: "..piececolor)
  printh(" ")
]]
end

function is_there_an_empty_neighbor(piece)
  if ((piece[2] > 1 and board[piece[1]][piece[2] - 1] == 0) or
      (piece[1] < 7 and piece[2] > 1 and board[piece[1] + 1][piece[2] - 1] == 0) or
      (piece[1] < 7 and board[piece[1] + 1][piece[2]] == 0) or
      (piece[2] < 7 and board[piece[1]][piece[2] + 1] == 0) or
      (piece[1] > 1 and piece[2] < 7 and board[piece[1] - 1][piece[2] + 1] == 0) or
      (piece[1] > 1 and board[piece[1] - 1][piece[2]] == 0)) 
  then return true
  else return false
  end
end

function is_mouse_inside_button(button_pos)
  return (mouse.x > button_pos[1] and mouse.x < button_pos[1] + 27 and mouse.y > button_pos[2] and mouse.y < button_pos[2] + 11)
end

--special print!
--used for printing the coordinate labels on the columns
--highlights the text for the row and column under the mouse
function s_print(str, x, y, col)
--[[
  if (curr_mouse_to_cell != nil) then 
    print(curr_mouse_to_cell[1], 8, 8, 7)
    print(curr_mouse_to_cell[2], 16, 8, 7)
  end
]]
  if (
    curr_mouse_to_cell != nil and (
    (str == "a" and (curr_mouse_to_cell[1] + curr_mouse_to_cell[2] == 5)) or
    (str == "b" and (curr_mouse_to_cell[1] + curr_mouse_to_cell[2] == 6)) or
    (str == "c" and (curr_mouse_to_cell[1] + curr_mouse_to_cell[2] == 7)) or
    (str == "d" and (curr_mouse_to_cell[1] + curr_mouse_to_cell[2] == 8)) or
    (str == "e" and (curr_mouse_to_cell[1] + curr_mouse_to_cell[2] == 9)) or
    (str == "f" and (curr_mouse_to_cell[1] + curr_mouse_to_cell[2] == 10)) or
    (str == "g" and (curr_mouse_to_cell[1] + curr_mouse_to_cell[2] == 11)) or
    (str == "1" and curr_mouse_to_cell[2] == 1) or
    (str == "2" and curr_mouse_to_cell[2] == 2) or
    (str == "3" and curr_mouse_to_cell[2] == 3) or
    (str == "4" and curr_mouse_to_cell[2] == 4) or
    (str == "5" and curr_mouse_to_cell[2] == 5) or
    (str == "6" and curr_mouse_to_cell[2] == 6) or
    (str == "7" and curr_mouse_to_cell[2] == 7)
      )) then
    bold_print(str, x, y, 14)
  else
   print(str, x, y, col)
  end
end

--prints with a thickblack background
function bold_print(str, x, y, col)
  palt(0, false)
  print(str, x - 1, y - 1, 0)
  print(str, x - 1, y, 0)
  print(str, x - 1, y + 1, 0)
  print(str, x, y - 1, 0)
  print(str, x, y + 1, 0)
  print(str, x + 1, y - 1, 0)
  print(str, x + 1, y, 0)
  print(str, x + 1, y + 1, 0)  
  print(str, x, y, col)
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
0000000070000000000000000000000006000000fffff99999fffffffffff88888fffffffffffbbbbbfffffffffffdddddffffff000008800000099000000000
0000000077000000000088800000000006000000fff999999999fffffff888888888fffffffbbbbbbbbbfffffffdddddddddffff000888800009999000000000
0070070077700000008888888000000006000000ff99999999999fffff88888888888fffffbbbbbbbbbbbfffffdddddddddddfff008888800099999000000000
0007700077770000088e88888200000006000000999999999999999f888888888888888fbbbbbbbbbbbbbbbfdddddddddddddddf888888809999999000000000
0007700000700000088888882200000006000000999999999999999f888888888888888fbbbbbbbbbbbbbbbfdddddddddddddddf888888809999999000000000
0070070000070000088888882200000006000000999999999999999f888888888888888fbbbbbbbbbbbbbbbfdddddddddddddddf888888809999999000000000
00000000000000000088888220000000e6000000999999999999999f888888888888888fbbbbbbbbbbbbbbbfdddddddddddddddf888888809999999000000000
00000000000000000000222000000000e6000000999999999999999f888888888888888fbbbbbbbbbbbbbbbfdddddddddddddddf888888809999999000000000
ffffffffffffffffffffffffffffffff06000000999999999999999f888888888888888fbbbbbbbbbbbbbbbfdddddddddddddddf888888809999999000000000
ffffff00000ffffffffffffff75fffff06000000449999999999944f228888888888822f33bbbbbbbbbbb33f11ddddddddddd11f228888804499999000000000
ffff007777700ffffffffffff775ffff06000000ff49999999994fffff28888888882fffff3bbbbbbbbb3fffff1ddddddddd1fff002888800049999000000000
fff07777777770fffffffffff7775fff06000000fff449999944fffffff228888822fffffff33bbbbb33fffffff11ddddd11ffff000228800004499000000000
f007777777777700fffffffff77775ff06000000fffff44444fffffffffff22222fffffffffff33333fffffffffff11111ffffff000002200000044000000000
07777777777777770ffffffff5575fff06000000ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff000000000000000000000000
07777777777777770ffffffffff575ff06000000ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff000000000000000000000000
07777777777777770fffffffffff5fff06000000ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff000000000000000000000000
07777777777777770ffffffff000000006000000ffffffffffffffffffffffffffffffffffffffffffffffffffffffff0000000000000bb000000dd000000000
07777777777777770fffffffffffffffe6000000ffffff00000fffffffffffffffffff00000ffffffffffffff75fffff00000000000bbbb0000dddd000000000
07777777777777770fffffffffffffffe6000000ffff002204400fffffffffffffff003301100ffffffffffff775ffff0000000000bbbbb000ddddd000000000
07777777777777770fffffffffffffff06000000fff02222044440fffffffffffff03333011110fffffffffff7775fff00000000bbbbbbb0ddddddd000000000
f007777777777700ffffffffffffffff06000000f002222204444400fffffffff003333301111100fffffffff77775ff00000000bbbbbbb0ddddddd000000000
fff07777777770ffffffffffffffffff0600000002222222044444440fffffff03333333011111110ffffffff5575fff00000000bbbbbbb0ddddddd000000000
ffff007777700fffffffffffffffffff0600000002222222044444440fffffff03333333011111110ffffffffff575ff00000000bbbbbbb0ddddddd000000000
ffffff00000fffffffffffffffffffff0600000002222222044444440fffffff03333333011111110fffffffffff5fff00000000bbbbbbb0ddddddd000000000
ffffffffffffffffffffffff000fffff0600000002222222044444440fffffff03333333011111110ffffffff000000000000000bbbbbbb0ddddddd000000000
ffffffffffffffffffffffff0700ffff6666666602222222044444440fffffff03333333011111110fffffffffffffff0000000033bbbbb011ddddd000000000
ffffffffffffffffffffffff07700fff0600000002222222044444440fffffff03333333011111110fffffffffffffff00000000003bbbb0001dddd000000000
ffffffffffffffffffffffff077700ff0600000002222222044444440fffffff03333333011111110fffffffffffffff0000000000033bb000011dd000000000
ffffffffffffffffffffffff077770ff06a00a00f002222204444400fffffffff003333301111100ffffffffffffffff00000000000003300000011000000000
ffffffffffffffffffffffff000700ff060aa0aafff02222044440fffffffffffff03333011110ffffffffffffffffff00000000000000000000000000000000
ffffffffffffffffffffffffff0070ff06000000ffff002204400fffffffffffffff003301100fffffffffffffffffff00000000000000000000000000000000
fffffffffffffffffffffffffff000ff06000000ffffff00000fffffffffffffffffff00000fffffffffffffffffffff00000000000000000000000000000000
ff00000000000000000000000fffffffff00000000000000000000000fffffffffffffffffffffffffffffffffffffff00000000000000000000000000000000
f0777777777777777777777770fffffff0777777777777777777777770ffffffffffffffffffffffffffffffffffffff00000000000000000000000000000000
077777777782888277777777770fffff0777777777777777b3777777770fffffffffffffffffffffffffffffffffffff00000000000000000000000000000000
077777777788277827777777770fffff077777777777777bb3777777770fffffffffffffffffffffffffffffffffffff00000000000000000000000000000000
077777777788827782777777770fffff0777777777b377bbb3777777770fffffffffffffffffffffffffffffffffffff00000000000000000000000000000000
077777777777777782777777770fffff0777777777bb3bbb37777777770fffffffffffffffffffffffffffffffffffff00000000000000000000000000000000
077777777782777782777777770fffff0777777777bbbbb377777777770fffffffffffffffffffffffffffffffffffff00000000000000000000000000000000
077777777778277827777777770fffff07777777777bbb3777777777770fffffffffffffffffffffffffffffffffffff00000000000000000000000000000000
077777777777888277777777770f0000077777777777b37777777777770f0000ffffffffffffffffffffffffffffffff00000000000000000000000000000000
f0777777777777777777777770ff0000f0777777777777777777777770ff0000ffffffffffffffffffffffffffffffff00000000000000000000000000000000
ff00000000000000000000000fff0000ff00000000000000000000000fff0000ffffffffffffffffffffffffffffffff00000000000000000000000000000000
ffffffffffffffffffffffffffff0000ffffffffffffffffffffffffffff0000ffffffffffffffffffffffffffffffff00000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000ffffffffffffffffffffffffffffffff00000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000ffffffffffffffffffffffffffffffff00000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000ffffffffffffffffffffffffffffffff00000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000ffffffffffffffffffffffffffffffff00000000000000000000000000000000
__sfx__
000100000962005010006000060000600006000060000600226000060025600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600
