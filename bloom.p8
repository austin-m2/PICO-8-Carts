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

  controlstate = "keyboard"
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

  offset = 0
  cpu = 0


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

  mouse_anchor_points = {
    {13, 29, nil, 5, nil, 2}, --red
    {23, 29, nil, 5, 1, nil}, --orange
    {103, 29, nil, 6, nil, 4}, --green
    {113, 29, nil, 6, 3, nil}, --purple
    {55, 114, nil, nil, 6, 6}, --undo  (todo: figure this out; these depend on whose turn it is)
    {87, 114, nil, nil, 5, 5}, --go
    {41, 28, 40, 11, 10, 8},  --1st row
    {57, 28, 41, 12, 7, 9},
    {73, 28, 42, 13, 8, 10},
    {89, 28, 43, 14, 9, 7},
    {33, 39, 7, 16, 15, 12},  --second row                 --up-right, down-left
    {49, 39, 8, 17, 11, 13},
    {65, 39, 9, 18, 12, 14},
    {81, 39, 10, 19, 13, 15},
    {97, 39, 10, 20, 14, 11},
    {25, 50, 11, 22, 21, 17},  --third row 
    {41, 50, 12, 23, 16, 18},
    {57, 50, 13, 24, 17, 19},
    {73, 50, 14, 25, 18, 20},
    {89, 50, 15, 26, 19, 21},
    {105, 50, 15, 27, 20, 16},
    {17, 61, 16, 29, 28, 23},  --fourth row
    {33, 61, 17, 29, 22, 24},
    {49, 61, 18, 30, 23, 25},
    {65, 61, 19, 31, 24, 26},
    {81, 61, 20, 32, 25, 27},
    {97, 61, 21, 33, 26, 28},
    {113, 61, 21, 34, 27, 22},
    {25, 72, 23, 35, 34, 30},  --fifth row
    {41, 72, 24, 35, 29, 31},
    {57, 72, 25, 36, 30, 32},
    {73, 72, 26, 37, 31, 33},
    {89, 72, 27, 38, 32, 34},
    {105, 72, 28, 39, 33, 29},
    {33, 83, 30, 40, 39, 36},  --sixth row
    {49, 83, 31, 40, 35, 37},
    {65, 83, 32, 41, 36, 38},
    {81, 83, 33, 42, 37, 39},
    {97, 83, 34, 43, 38, 35},
    {41, 97, 36, 7, 43, 41},  --seventh row
    {57, 94, 37, 8, 40, 42},
    {73, 94, 38, 9, 41, 43},
    {89, 94, 39, 10, 42, 40}
  }

function _init()
	init_keys()
	mouse_init()
	cells_init()
  columns_init()
  buttons_init()

  make_starfield_ps()
  gamestate = "turn1"
end

function _update60()
  cpu = 0

	upd_keys()
  printh(stat(1) - cpu..": upd_keys()")
  cpu = stat(1)

  mouse_update()
  printh(stat(1) - cpu..": mouse_update()")
  cpu = stat(1)


  cells_update()
  printh(stat(1) - cpu..": cells_update()")
  cpu = stat(1)


  game_update()
  printh(stat(1) - cpu..": game_update()")
  cpu = stat(1)

  update_psystems()

  columns_update()
  printh(stat(1) - cpu..": columns_update()")
  cpu = stat(1)

  buttons_update()
  printh(stat(1) - cpu..": buttons_update()")
  cpu = stat(1)
end

function _draw()
  screen_shake()
  --draw background
	rectfill(0,0,127,127,12)

  draw_ps(particle_systems[1]) --draw starfield background

  cpu = stat(1)

  columns_draw()
  printh(stat(1) - cpu..": columns_draw()")
  cpu = stat(1)


  cells_draw()
  printh(stat(1) - cpu..": cells_draw()")
  cpu = stat(1)

  for ps in all(particle_systems) do
    if (ps != particle_systems[1]) draw_ps(ps)
  end


  buttons_draw()
  printh(stat(1) - cpu..": buttons_draw()")
  cpu = stat(1)

  text_draw()
  printh(stat(1) - cpu..": text_draw()")
  cpu = stat(1)

	--gems_draw()
	mouse_draw()
  printh(stat(1) - cpu..": cells_draw()\n\n\n")


  --print(mouse.x, 0, 0, 7)
  --print(mouse.y, 16, 0, 7)


  if (gamestate == "end") then
    if (p1score > p2score) then
      bold_print("player 1 wins~!", 36, 8, 7)
    else
      bold_print("player 2 wins~!", 36, 8, 7)
    end
  end


  print(stat(1), 8, 8, 7)
end

function mouse_init() 
	--enable mouse support
	poke(0x5f2d, 1)
  mouse.pos = 1

	for sx = 8, 11 do
		for sy = 0, 5 do
			if (sget(sx, sy) == 7) then
				add(mouse_pixels, {sx - 8, sy})
			end
		end
	end

end

function mouse_update()
  mouse_anchor_points_update()

  if (controlstate == "mouse") then
    --check if player wants to switch to keyboard control
    if (is_pressed(0) or is_pressed(1) or is_pressed(2) or (is_pressed(3))) then 
      controlstate = "keyboard"
    
      --move the mouse to a valid position
      if (gamestate == "turn1" or gamestate == "player1") mouse.pos = 2
      if (gamestate == "player2") mouse.pos = 3
    end
  else
    --check if player wants to switch to mouse control
    if (is_pressed(6)) controlstate = "mouse"
  end


  if (controlstate == "mouse") then
    mouse.x = stat(32)
    mouse.y = stat(33)
  else --controlstate == "keyboard"
    --move the mouse!
    move_mouse()
    mouse.x = mouse_anchor_points[mouse.pos][1]
    mouse.y = mouse_anchor_points[mouse.pos][2]

    if (mouse.pos == 1 or mouse.pos == 2) mouse.y -= p1score
    if (mouse.pos == 3 or mouse.pos == 4) mouse.y -= p2score

  end

  cpu = stat(1)
  curr_mouse_to_cell = mouse_to_cell()

  printh(stat(1) - cpu..": mouse_to_cell() and mouse_to_cell_coords()")
end

function mouse_draw()
palt(0, false)
palt(15, true)
if (controlstate == "keyboard") spr(51, mouse.x, mouse.y)
end	

--move the mouse to the desired anchor point (in keyboard mode)
function move_mouse()
  if (btnp(2) and mouse_anchor_points[mouse.pos][3] != nil) mouse.pos = mouse_anchor_points[mouse.pos][3] --up
  if (btnp(3) and mouse_anchor_points[mouse.pos][4] != nil) mouse.pos = mouse_anchor_points[mouse.pos][4] --down
  if (btnp(0) and mouse_anchor_points[mouse.pos][5] != nil) mouse.pos = mouse_anchor_points[mouse.pos][5] --left
  if (btnp(1) and mouse_anchor_points[mouse.pos][6] != nil) mouse.pos = mouse_anchor_points[mouse.pos][6] --right
end

function mouse_anchor_points_update()
  if (gamestate == "turn1") then
    --update where the cursor should go from the bottom buttons
    mouse_anchor_points[5][3] = 2
    mouse_anchor_points[6][3] = 2

    --update whether the cursor should be able to go to the bottom buttons
    if (p1choice1 == nil and p1choice2 == nil) then
      mouse_anchor_points[1][4] = nil
      mouse_anchor_points[2][4] = nil
    else
      mouse_anchor_points[1][4] = 5
      mouse_anchor_points[2][4] = 5
    end
  end

  if (gamestate == "player1") then
    --update where the cursor should go from the bottom buttons
    mouse_anchor_points[5][3] = 2
    mouse_anchor_points[6][3] = 2

    --update whether the cursor should be able to go to the bottom buttons
    if (p1choice1 == nil and p1choice2 == nil) then
      mouse_anchor_points[1][4] = nil
      mouse_anchor_points[2][4] = nil
    else
      mouse_anchor_points[1][4] = 5
      mouse_anchor_points[2][4] = 5
    end
  end

  if (gamestate == "player2") then
    --update where the cursor should go from the bottom buttons
    mouse_anchor_points[5][3] = 3
    mouse_anchor_points[6][3] = 3
  end

      --update whether the cursor should be able to go to the bottom buttons
    if (p2choice3 == nil and p2choice4 == nil) then
      mouse_anchor_points[3][4] = nil
      mouse_anchor_points[4][4] = nil
    else
      mouse_anchor_points[3][4] = 5
      mouse_anchor_points[4][4] = 5
    end
end

function game_update()

  if (gamestate == "turn1") then
    --check if player is trying to paste a move
    if (is_pressed(5)) then
      move = ''..stat(4)
      if (#move == 3) then
        --get the numbers from the pasted string
        a = tonum(sub(move, 1, 1))
        b = tonum(sub(move, 2, 2))
        c = tonum(sub(move, 3, 3))

        --put the piece down if it is valid
        if (a == 1 and board[b][c] == 0) then
          board[b][c] = 1
          p1choice1 = {b, c}
        elseif (a == 2 and board[b][c] == 0) then
          board[b][c] = 2
          p1choice2 = {b, c}
        end
      end
    end

    --check if player is choosing a color
    if ((is_pressed(6) or is_pressed(4)) and dist(mouse.x, mouse.y, left_column_pos[1] + 8, left_column_pos[2] + 8) < 7.5) then
      if (p1choice1 == nil and p1choice2 == nil and mouse.x < left_column_pos[1] + 8) then 
        colorchoice = 2
        left_column_pos[2] += 3
        mouse.pos = 7
        sfx(2)
      end 
      if (p1choice2 == nil and p1choice1 == nil and mouse.x > left_column_pos[1] + 8) then 
        colorchoice = 1
        left_column_pos[2] += 3
        mouse.pos = 7
        sfx(2)
      end

    --check whether a piece should be put down
    elseif ((is_pressed(6) or is_pressed(4))) then
      if (curr_mouse_to_cell != nil and board[curr_mouse_to_cell[1]][curr_mouse_to_cell[2]] == 0)  then
        if ((p1choice1 == nil and p1choice2 == nil and colorchoice == 1) or (p1choice1 == nil and p1choice2 == nil and colorchoice == 2)) then --put a piece down!
          board[curr_mouse_to_cell[1]][curr_mouse_to_cell[2]] = colorchoice
          if (colorchoice == 1) then 
            p1choice1 = curr_mouse_to_cell
            colorchoice = 0
            mouse.pos = 6
            sfx(1)
          elseif (colorchoice == 2) then
            p1choice2 = curr_mouse_to_cell
            colorchoice = 0
            mouse.pos = 6
            sfx(1)
          end
        end
      end
    end

    --check whether the player is trying to delete their pieces (lshift)
    if ((is_pressed(6) or is_pressed(4)) and is_mouse_inside_button(undo_button_pos)) then
    --if (btn(4, 1)) then
      if (p1choice1 != nil) then
        board[p1choice1[1]][p1choice1[2]] = 0
        p1choice1 = nil
      end
      if (p1choice2 != nil) then
        board[p1choice2[1]][p1choice2[2]] = 0
        p1choice2 = nil
      end  
      mouse.pos = 2
      colorchoice = 0    
    end

    --check whether the player wants to end their turn
    if ((is_pressed(6) or is_pressed(4)) and is_mouse_inside_button(go_button_pos) and (p1choice1 != nil or p1choice2 != nil)) then
        --copy the move to the clipboard if online mode is enabled!
        if (is_online_mode_enabled) then
          move = ''
          if (p1choice1 != nil) move = move..'1'..p1choice1[1]..p1choice1[2]
          if (p1choice2 != nil) move = move..'2'..p1choice2[1]..p1choice2[2]
          printh(''..move,'@clip') 
        end

        gamestate = "p1top2"
        p1choice1 = nil
        p1choice2 = nil
        colorchoice = 0
        mouse.pos = 3
    end
  end


  if (gamestate == "player1") then
    --check if player is trying to paste a move
    if (is_pressed(5)) then
      move = ''..stat(4)
      if (#move == 3) then
        --get the numbers from the pasted string
        a = tonum(sub(move, 1, 1))
        b = tonum(sub(move, 2, 2))
        c = tonum(sub(move, 3, 3))

        --put the piece down if it is valid
        if (a == 1 and board[b][c] == 0) then
          board[b][c] = 1
          p1choice1 = {b, c}
        elseif (a == 2 and board[b][c] == 0) then
          board[b][c] = 2
          p1choice2 = {b, c}
        end
      elseif(#move == 6) then
        --get the numbers from the pasted string
        b = tonum(sub(move, 2, 2))
        c = tonum(sub(move, 3, 3))
        e = tonum(sub(move, 5, 5))
        f = tonum(sub(move, 6, 6))

        --put the pieces down if they are valid
        if (board[b][c] == 0) then
          board[b][c] = 1
          p1choice1 = {b, c}
        end
        if (board[e][f] == 0) then
          board[e][f] = 2
          p1choice2 = {e, f}
        end
      else
      end
    end


    --check if player is choosing a color
    if ((is_pressed(6) or is_pressed(4)) and dist(mouse.x, mouse.y, left_column_pos[1] + 8, left_column_pos[2] + 8) < 7.5) then
      if (p1choice2 == nil and mouse.x < left_column_pos[1] + 8) then
        colorchoice = 2
        left_column_pos[2] += 3
        mouse.pos = 7
        sfx(2)
      end
      if (p1choice1 == nil and mouse.x > left_column_pos[1] + 8) then
        colorchoice = 1
        left_column_pos[2] += 3
        mouse.pos = 7
        sfx(2)
      end

    --check whether a piece should be put down
    elseif ((is_pressed(6) or is_pressed(4))) then
      if (curr_mouse_to_cell != nil and board[curr_mouse_to_cell[1]][curr_mouse_to_cell[2]] == 0)  then
        if ((p1choice1 == nil and colorchoice == 1) or (p1choice2 == nil and colorchoice == 2)) then --put a piece down!
          board[curr_mouse_to_cell[1]][curr_mouse_to_cell[2]] = colorchoice
          if (colorchoice == 1) then 
            p1choice1 = curr_mouse_to_cell
            colorchoice = 0
            sfx(1)
            if (p1choice2 == nil) then mouse.pos = 1
            else mouse.pos = 6 end
          elseif (colorchoice == 2) then
            p1choice2 = curr_mouse_to_cell
            colorchoice = 0
            sfx(1)
            if (p1choice1 == nil) then mouse.pos = 2
            else mouse.pos = 6 end
          end
        end
      end
    end

    --check whether the player is trying to delete their pieces (lshift)
    if ((is_pressed(6) or is_pressed(4)) and is_mouse_inside_button(undo_button_pos)) then
    --if (btn(4, 1)) then
      if (p1choice1 != nil) then
        board[p1choice1[1]][p1choice1[2]] = 0
        p1choice1 = nil
      end
      if (p1choice2 != nil) then
        board[p1choice2[1]][p1choice2[2]] = 0
        p1choice2 = nil
      end     
      mouse.pos = 2
      colorchoice = 0 
    end

    --check whether the player wants to end their turn
    if ((is_pressed(6) or is_pressed(4)) and is_mouse_inside_button(go_button_pos) and (p1choice1 != nil or p1choice2 != nil)) then
      --copy the move to the clipboard if online mode is enabled!
      if (is_online_mode_enabled) then
        move = ''
        if (p1choice1 != nil) move = move..'1'..p1choice1[1]..p1choice1[2]
        if (p1choice2 != nil) move = move..'2'..p1choice2[1]..p1choice2[2]
        printh(''..move,'@clip') 
      end
      gamestate = "p1top2"
      p1choice1 = nil
      p1choice2 = nil
      colorchoice = 0
      mouse.pos = 3
    end
  end

  if (gamestate == "player2") then
    --check if player is trying to paste a move
    if (is_pressed(5)) then
      move = ''..stat(4)
      if (#move == 3) then
        --get the numbers from the pasted string
        a = tonum(sub(move, 1, 1))
        b = tonum(sub(move, 2, 2))
        c = tonum(sub(move, 3, 3))

        --put the piece down if it is valid
        if (a == 3 and board[b][c] == 0) then
          board[b][c] = 3
          p1choice1 = {b, c}
        elseif (a == 4 and board[b][c] == 0) then
          board[b][c] = 4
          p1choice2 = {b, c}
        end
      elseif(#move == 6) then
        --get the numbers from the pasted string
        b = tonum(sub(move, 2, 2))
        c = tonum(sub(move, 3, 3))
        e = tonum(sub(move, 5, 5))
        f = tonum(sub(move, 6, 6))

        --put the pieces down if they are valid
        if (board[b][c] == 0) then
          board[b][c] = 3
          p2choice3 = {b, c}
        end
        if (board[e][f] == 0) then
          board[e][f] = 4
          p2choice4 = {e, f}
        end
      else
      end
    end

    --check if player is choosing a color
    if ((is_pressed(6) or is_pressed(4)) and dist(mouse.x, mouse.y, right_column_pos[1] + 8, right_column_pos[2] + 8) < 7.5) then
      if (p2choice3 == nil and mouse.x < right_column_pos[1] + 8) then
        colorchoice = 3
        right_column_pos[2] += 3
        mouse.pos = 10
        sfx(2)
      end
      if (p2choice4 == nil and mouse.x > right_column_pos[1] + 8) then 
        colorchoice = 4
        right_column_pos[2] += 3
        mouse.pos = 10
        sfx(2)
      end

    --check whether a piece should be put down
    elseif ((is_pressed(6) or is_pressed(4))) then
      if (curr_mouse_to_cell != nil and board[curr_mouse_to_cell[1]][curr_mouse_to_cell[2]] == 0)  then
        if ((p2choice3 == nil and colorchoice == 3) or (p2choice4 == nil and colorchoice == 4)) then --put a piece down!
          board[curr_mouse_to_cell[1]][curr_mouse_to_cell[2]] = colorchoice
          if (colorchoice == 3) then 
            p2choice3 = curr_mouse_to_cell
            colorchoice = 0
            sfx(1)
            if (p2choice4 == nil) then mouse.pos = 4
            else mouse.pos = 6 end
          elseif (colorchoice == 4) then
            p2choice4 = curr_mouse_to_cell
            colorchoice = 0
            sfx(1)
            if (p2choice3 == nil) then mouse.pos = 3
            else mouse.pos = 6 end
          end
        end
      end
    end

    --check whether the player is trying to delete their pieces (lshift)
    if ((is_pressed(6) or is_pressed(4)) and is_mouse_inside_button(undo_button_pos)) then
    --if (btn(4, 1)) then
      if (p2choice3 != nil) then
        board[p2choice3[1]][p2choice3[2]] = 0
        p2choice3 = nil
      end
      if (p2choice4 != nil) then
        board[p2choice4[1]][p2choice4[2]] = 0
        p2choice4 = nil
      end      
      mouse.pos = 3
      colorchoice = 0
    end

    --check whether the player wants to end their turn
    if ((is_pressed(6) or is_pressed(4)) and is_mouse_inside_button(go_button_pos) and (p2choice3 != nil or p2choice4 != nil)) then
      --copy the move to the clipboard if online mode is enabled!
      if (is_online_mode_enabled) then
        move = ''
        if (p2choice3 != nil) move = move..'3'..p2choice3[1]..p2choice3[2]
        if (p2choice4 != nil) move = move..'4'..p2choice4[1]..p2choice4[2]
        printh(''..move,'@clip') 
      end
        gamestate = "p2top1"
        p2choice3 = nil
        p2choice4 = nil
        colorchoice = 0
        mouse.pos = 2
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
      sfx(3)
      for piece in all(bloom) do
        make_sparks_ps(cells[board_coords_to_index(piece[1], piece[2])].x + 9, cells[board_coords_to_index(piece[1], piece[2])].y + 10, board[piece[1]][piece[2]])
        board[piece[1]][piece[2]] = 0
        cells[board_coords_to_index(piece[1], piece[2])].y = cell_coords[board_coords_to_index(piece[1], piece[2])][2] + 20
        p1score += 1
        offset += .1
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
      sfx(3)
      for piece in all(bloom) do
        make_sparks_ps(cells[board_coords_to_index(piece[1], piece[2])].x + 9, cells[board_coords_to_index(piece[1], piece[2])].y + 10, board[piece[1]][piece[2]])
        board[piece[1]][piece[2]] = 0
        cells[board_coords_to_index(piece[1], piece[2])].y = cell_coords[board_coords_to_index(piece[1], piece[2])][2] + 20
        p2score += 1
        offset += .1
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
    local index = index_to_board_coords(i)
    if ((gamestate == "turn1" or gamestate == "player1") and (board[index[1]][index[2]] == 1 or board[index[1]][index[2]] == 2)) then
      value.y = lerp(value.y, cell_coords[i][2] - 3, 0.06)
    elseif (gamestate == "player2" and (board[index[1]][index[2]] == 3 or board[index[1]][index[2]] == 4)) then
      value.y = lerp(value.y, cell_coords[i][2] - 3, 0.06)
    else
      value.y = lerp(value.y, cell_coords[i][2] - .9, 0.06)
    end

    i+=1
  end
  
  --lerp the cell under the mouse upward
  closestcell = curr_mouse_to_cell_coords
  if (closestcell == nil) return
  --if there is a tile there, don't lerp upward
  local index = index_to_board_coords(closestcell)
  if (board[index[1]][index[2]] != 0) return
  cells[closestcell].y = lerp(cells[closestcell].y, cell_coords[closestcell][2] - 7, 0.015)

  --push the cell downward when you click
  if ((is_pressed(6) or is_pressed(4))) then
    --cells[closestcell].y = lerp(cells[closestcell].y, cell_coords[closestcell][2] + 20, 0.05)
    cells[closestcell].y = cell_coords[closestcell][2] + 4
  end
end

function cells_draw()
  palt(0, false)
  palt(15, true)

  local board_index = 1
	for v in all(cells) do

    if (board_index == 16 or board_index == 23 or board_index == 29 or board_index == 34 or board_index == 35 or board_index == 36 or board_index == 37 or board_index == 33 or board_index == 28 or board_index == 22) then
      rectfill(v.x + 1, v.y + 13, v.x + 7, 127, 6)
      rectfill(v.x + 9, v.y + 13, v.x + 15, 127, 5)
      line(v.x, v.y + 12, v.x, 127, 0)
      line(v.x + 8, v.y + 15, v.x + 8, 127, 0)
      line(v.x + 16, v.y + 12, v.x + 16, 127, 0)
    else
      rectfill(v.x + 1, v.y + 13, v.x + 7, v.y + 19, 6)
      rectfill(v.x + 9, v.y + 13, v.x + 15, v.y + 19, 5)
      line(v.x, v.y + 12, v.x, v.y + 17, 0)
      line(v.x + 8, v.y + 15, v.x + 8, v.y + 20, 0)
      line(v.x + 16, v.y + 12, v.x + 16, v.y + 17, 0)
    end

    if (board_index == curr_mouse_to_cell_coords) then pal(7, 15, 0) end
		sspr(cell.spritesheet_x, cell.spritesheet_y, cell.width, cell.height, v.x, v.y, cell.width, cell.height) --draw the actual empty cell
    pal(7, 7, 0)

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
	if ((is_pressed(6) or is_pressed(4))) then

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

function screen_shake()
  local fade = 0.85
  local offset_x=16-rnd(32)
  local offset_y=16-rnd(32)
  offset_x*=offset
  offset_y*=offset
  
  camera(offset_x,offset_y)
  offset*=fade
  if offset<0.05 then
    offset=0
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
  curr_mouse_to_cell_coords = coords_index
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
   --printh("("..piece[1]..","..piece[2]..") ")
  end
  --printh("piececolor: "..piececolor)
  --printh(" ")
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

-- particle system library -----------------------------------
-- todo: lots of this stuff could be stripped out!!
particle_systems = {}

function make_psystem(minlife, maxlife, minstartsize, maxstartsize, minendsize, maxendsize)
  local ps = {}
  -- global particle system params
  ps.autoremove = true

  ps.minlife = minlife
  ps.maxlife = maxlife
  
  ps.minstartsize = minstartsize
  ps.maxstartsize = maxstartsize
  ps.minendsize = minendsize
  ps.maxendsize = maxendsize
  
  -- container for the particles
  ps.particles = {}

  -- emittimers dictate when a particle should start
  -- they called every frame, and call emit_particle when they see fit
  -- they should return false if no longer need to be updated
  ps.emittimers = {}

  -- emitters must initialize p.x, p.y, p.vx, p.vy
  ps.emitters = {}

  -- every ps needs a drawfunc
  ps.drawfuncs = {}

  -- affectors affect the movement of the particles
  ps.affectors = {}

  add(particle_systems, ps)

  return ps
end

function update_psystems()
  local timenow = time()
  for ps in all(particle_systems) do
    update_ps(ps, timenow)
  end
end

function update_ps(ps, timenow)
  for et in all(ps.emittimers) do
    local keep = et.timerfunc(ps, et.params)
    if (keep==false) then
      del(ps.emittimers, et)
    end
  end

  for p in all(ps.particles) do
    p.phase = (timenow-p.starttime)/(p.deathtime-p.starttime)

    for a in all(ps.affectors) do
      a.affectfunc(p, a.params)
    end

    p.x += p.vx
    p.y += p.vy
    
    local dead = false
    if (p.x<0 or p.x>127 or p.y<0 or p.y>127) then
      dead = true
    end

    if (timenow>=p.deathtime) then
      dead = true
    end

    if (dead==true) then
      del(ps.particles, p)
    end
  end
  
  if (ps.autoremove==true and count(ps.particles)<=0) then
    del(particle_systems, ps)
  end
end

function draw_ps(ps, params)
  for df in all(ps.drawfuncs) do
    df.drawfunc(ps, df.params)
  end
end

function deleteallps()
  for ps in all(particle_systems) do
    del(particle_systems, ps)
  end
end

function emittimer_burst(ps, params)
  for i=1,params.num do
    emit_particle(ps)
  end
  return false
end

function emittimer_constant(ps, params)
  if (params.nextemittime<=time()) then
    emit_particle(ps)
    params.nextemittime += params.speed
  end
  return true
end

function emit_particle(psystem)
  local p = {}

  local e = psystem.emitters[flr(rnd(#(psystem.emitters)))+1]
  e.emitfunc(p, e.params) 

  p.phase = 0
  p.starttime = time()
  p.deathtime = time()+rnd(psystem.maxlife-psystem.minlife)+psystem.minlife

  p.startsize = rnd(psystem.maxstartsize-psystem.minstartsize)+psystem.minstartsize
  p.endsize = rnd(psystem.maxendsize-psystem.minendsize)+psystem.minendsize

  add(psystem.particles, p)
end

function emitter_point(p, params)
  p.x = params.x
  p.y = params.y

  p.vx = rnd(params.maxstartvx-params.minstartvx)+params.minstartvx
  p.vy = rnd(params.maxstartvy-params.minstartvy)+params.minstartvy
end

function emitter_box(p, params)
  p.x = rnd(params.maxx-params.minx)+params.minx
  p.y = rnd(params.maxy-params.miny)+params.miny

  p.vx = rnd(params.maxstartvx-params.minstartvx)+params.minstartvx
  p.vy = rnd(params.maxstartvy-params.minstartvy)+params.minstartvy
end

function affect_force(p, params)
  p.vx += params.fx
  p.vy += params.fy
end

function affect_forcezone(p, params)
  if (p.x>=params.zoneminx and p.x<=params.zonemaxx and p.y>=params.zoneminy and p.y<=params.zonemaxy) then
    p.vx += params.fx
    p.vy += params.fy
  end
end

function affect_stopzone(p, params)
  if (p.x>=params.zoneminx and p.x<=params.zonemaxx and p.y>=params.zoneminy and p.y<=params.zonemaxy) then
    p.vx = 0
    p.vy = 0
  end
end

function affect_bouncezone(p, params)
  if (p.x>=params.zoneminx and p.x<=params.zonemaxx and p.y>=params.zoneminy and p.y<=params.zonemaxy) then
    p.vx = -p.vx*params.damping
    p.vy = -p.vy*params.damping
  end
end

function affect_attract(p, params)
  if (abs(p.x-params.x)+abs(p.y-params.y)<params.mradius) then
    p.vx += (p.x-params.x)*params.strength
    p.vy += (p.y-params.y)*params.strength
  end
end

function affect_orbit(p, params)
  params.phase += params.speed
  p.x += sin(params.phase)*params.xstrength
  p.y += cos(params.phase)*params.ystrength
end

function draw_ps_fillcirc(ps, params)
  for p in all(ps.particles) do
    c = flr(p.phase*count(params.colors))+1
    r = (1-p.phase)*p.startsize+p.phase*p.endsize
    circfill(p.x,p.y,r,params.colors[c])
  end
end

function draw_ps_pixel(ps, params)
  for p in all(ps.particles) do
    c = flr(p.phase*count(params.colors))+1
    pset(p.x,p.y,params.colors[c])
  end 
end

function draw_ps_streak(ps, params)
  for p in all(ps.particles) do
    c = flr(p.phase*count(params.colors))+1
    line(p.x,p.y,p.x-p.vx,p.y-p.vy,params.colors[c])
  end 
end

function draw_ps_animspr(ps, params)
  params.currframe += params.speed
  if (params.currframe>count(params.frames)) then
    params.currframe = 1
  end
  for p in all(ps.particles) do
    pal(7,params.colors[flr(p.endsize)])
    spr(params.frames[flr(params.currframe+p.startsize)%count(params.frames)],p.x,p.y)
  end
  pal()
end

function draw_ps_agespr(ps, params)
  for p in all(ps.particles) do
    local f = flr(p.phase*count(params.frames))+1
    spr(params.frames[f],p.x,p.y)
  end 
end

function draw_ps_rndspr(ps, params)
  for p in all(ps.particles) do
    pal(7,params.colors[flr(p.endsize)])
    spr(params.frames[flr(p.startsize)],p.x,p.y)
  end 
  pal()
end

function make_sparks_ps(ex,ey, col)
  local ps = make_psystem(0.3,0.7, 1,2,0.5,0.5)
  
  add(ps.emittimers,
    {
      timerfunc = emittimer_burst,
      params = { num = 10}
    }
  )
  add(ps.emitters, 
    {
      emitfunc = emitter_point,
      params = { x = ex, y = ey, minstartvx = -1.5, maxstartvx = 1.5, minstartvy = -3, maxstartvy=-2 }
    }
  )
  if (col == 1) arr = {7,15,10,9,9,4}
  if (col == 2) arr = {7,15,14,8,8,2}
  if (col == 3) arr = {7,11,11,3,3,1}
  if (col == 4) arr = {7,12,13,13,1,5}
  add(ps.drawfuncs,
    {

      drawfunc = draw_ps_fillcirc,
      params = { colors = arr }
      --params = { colors = {7,10,15,9,4,5} }
    }
  )
  add(ps.affectors,
    { 
      affectfunc = affect_force,
      params = { fx = 0, fy = 0.3 }
    }
  )
end

function make_starfield_ps()
   local ps = make_psystem(10,20, 1,2,0.5,0.5)
   ps.autoremove = false
   add(ps.emittimers,
       {
           timerfunc = emittimer_constant,
           params = {nextemittime = time(), speed = 0.20}
       }
   )
   add(ps.emitters, 
       {
           emitfunc = emitter_box,
           params = { minx = 0, maxx = 127, miny = 127, maxy= 127, minstartvx = -0.2, maxstartvx = 0.2, minstartvy = -0.5, maxstartvy=-0.1 }
       }
   )
   add(ps.drawfuncs,
       {
           drawfunc = draw_ps_pixel,
           params = { colors = {10,7,10,7,10,10,7,10,7,10,10,7,10,10} }
           --params = { colors = {7,6,7,6,7,6,6,7,6,7,7,6,6,7} }
       }
   )
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
0000000077000000000088800000000006000000ffff9999999fffffffff8888888fffffffffbbbbbbbfffffffffdddddddfffff000888800009999000000000
0070070077700000008888888000000006000000ff99999999999fffff88888888888fffffbbbbbbbbbbbfffffdddddddddddfff008888800099999000000000
0007700077770000088e88888200000006000000999999999999999f888888888888888fbbbbbbbbbbbbbbbfdddddddddddddddf888888809999999000000000
0007700000700000088888882200000006000000999999999999999f888888888888888fbbbbbbbbbbbbbbbfdddddddddddddddf888888809999999000000000
0070070000070000088888882200000006000000999999999999999f888888888888888fbbbbbbbbbbbbbbbfdddddddddddddddf888888809999999000000000
00000000000000000088888220000000e6000000999999999999999f888888888888888fbbbbbbbbbbbbbbbfdddddddddddddddf888888809999999000000000
00000000000000000000222000000000e6000000999999999999999f888888888888888fbbbbbbbbbbbbbbbfdddddddddddddddf888888809999999000000000
ffffffffffffffffffffffffffffffff06000000999999999999999f888888888888888fbbbbbbbbbbbbbbbfdddddddddddddddf888888809999999000000000
ffffff00000ffffffffffffff75fffff06000000449999999999944f228888888888822f33bbbbbbbbbbb33f11ddddddddddd11f228888804499999000000000
fffff0777770fffffffffffff775ffff06000000ff49999999994fffff28888888882fffff3bbbbbbbbb3fffff1ddddddddd1fff002888800049999000000000
fff00777777700fffffffffff7775fff06000000fff449999944fffffff228888822fffffff33bbbbb33fffffff11ddddd11ffff000228800004499000000000
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
010100000962005010006000060000600006000060000600226000060025600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600
000100001a60416611116110b7210f731127411775011700177001170014700177001b700187001c7002370026700006000060000600006000060000600006000060000600006000060000600006000060000600
000100001a60016610116100f72013730167401b75011700177001170014700177001b700187001c7002370026700006000060000600006000060000600006000060000600006000060000600006000060000600
00020000096500e2300d2300c2200a220090200902509020070100601004010040100301003010020100101001010003000030000300003000030000300003000030000300003000030000300003000030000300
