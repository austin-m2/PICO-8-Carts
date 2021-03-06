pico-8 cartridge // http://www.pico-8.com
version 7
__lua__
--star beast

--credits
--raycast engine code borrowed from lode's computer graphics tutorial
--http://lodev.org/cgtutor/raycasting.html
-- horizontal distortion effect borrowed from qbicfeet



--change log
--1/12/2016
--doors now display solid until you walk up to them. (code is a bit messy there...)
--added bullet hole decals
--added bullet holes in enemies
--sprites can now be different heights and widths (not just 1x2
--added hud for health and score
--added picks for health and coins
--sprites can be on floor or cieling or floating
--implement map as sparse matrix
--implement map loader into sparse matrix
--implement 2d map viewer for sparse matrix
--map generation into sparse matrix
--added room styles with vents

--added treasure rooms
--added doors
--monsters can't open doors (too much checking!)
--removed compound rooms

--1/18/2016
--fixed double load of rooms, which lowered frame rate and prevented items from disappearing when picked up
--added more sound effects for doors, shots, damage etc
--reduced map size a bit to improve speed
--enemy shots go through doors (open or otherwise) 


k_title_mode = 1
k_play_mode = 2
k_credits_mode = 3
game_mode=k_title_mode


k_use_sparse_map=true
map_mode=false
map_x=0
map_y=0

clock_start =0
clock_stop = 0


map_width=64
map_height=32

h_res = 128
h = 128
w = 128
v_res = 127
focal_length = .8
rot_speed = .02

view_dist = 20

tex_width = 8
tex_height = 8



vx=0
vy=0

y_scale=1.5

pix_width=2


plane_x = 0
plane_y = 0.66 --raycast plane
speed = .5


--screen_center_x=32
--screen_center_y=64
screen_height=112

screen_start_x=flr((127-h_res)/2)
screen_width=h_res+screen_start_x
screen_start_y=16

ground_y=10

h_step = 2
v_step = 1

z_buffer={}


time = 0
old_time = 0

frame=0

center_target={}

k_sound_player_shot = 0
k_sound_enemy_shot = 1
k_sound_player_damage = 2
k_sound_pickup = 3
k_sound_door = 4
k_sound_enemy_damage =5
k_sound_enemy_explode = 6


sparse_map={}
function init_sparse_map()

	if(k_use_sparse_map)then
	mget=sparse_mget
	mset=sparse_mset
end

	sparse_map={}
end

function sparse_mset(mx,my,val)
	mx=flr(mx)
	my=flr(my)
	
	if(sparse_map[my]==nil)then
		sparse_map[my]={}
	end
	
	sparse_map[my][mx]=val

end

function sparse_mget(mx,my)
	mx=flr(mx)
	my=flr(my)

	
	if(sparse_map[my]==nil)then return 0 end
	
	if(sparse_map[my][mx]==nil) then return 0 end
	
	return( sparse_map[my][mx] )

end

--overload the map functions to use the sparse matrix


function	sparse_draw()
	
	for my=0,map_height do
		for mx=0,map_width do
			tile = sparse_mget(mx,my)
			sspr(tile%16*8,flr(tile/16)*8,8,8,mx*4+map_x,my*4+map_y,4,4)
		end
	end


end


function	check_clear(x,y,w,h)
	for my=y,y+h do
		for mx=x,x+w do
			if(mget(mx,my)!=0)then return false end
		end
	
	end
	return true
end

function sparse_toggle(mx,my,tile)
	if(mget(mx,my)==16 or mget(mx,my)==0)then mset(mx,my,tile) else mset(mx,my,16) end
end

--room_types
k_normal_room=0
k_lobby_room=1
k_server_room=2
k_column_room=3
k_treasure_room=4
k_dining_room=5
k_elevator_room=6

k_up=0
k_down=1
k_left=2
k_right=3
k_door_odds=.4
k_max_width=10
k_min_width=5
k_start_depth=5
k_vent_odds=1.05
k_door_odds=.5


k_tree_odds = .25

function new_room_type()
	r=rnd(100)
	
	if(r<10)then return k_lobby_room
	elseif(r<20)then return k_server_room
	elseif(r<30)then return k_column_room
	elseif(r<40)then return treasure_room
	elseif(r<50)then return k_dining_room
	elseif(r<60)then return k_office_room
	else return k_normal_room
	end
	
end


function rand_size()
	return flr(rnd(k_max_width-k_min_width))+k_min_width
end
--x,y is the location of the starting point of the center of the room
function make_room(x,y,w,h,direction,depth,parent_style,parent_tl_x,parent_tl_y,parent_br_x,parent_br_y)

	if(parent_style==nil)then parent_style=1 end
	
	room_type = new_room_type()
	
	if(room_type!=k_normal_room)then h=min(6,h) w=min(6,8) end
	
	--draw top and bottom line

	if(depth<0)then return false end
	local start_room = false
	if(depth==k_start_depth)then start_room=true end
	
	local half_height=flr(h/2)
	local half_width=flr(w/2)
	local tl_x
	local tl_y
	local br_x
	local br_y
	local made_room
	local mx
	local my

	local style
	local temp
	
	
	--add on to existing room?
	
		temp = flr(rnd(3))
		if(temp==0)then style=1
		elseif(temp==1)then style=5
		elseif(temp==2)then style=9
		else style=1
		end
	
	
	

	if(direction==k_right) then
		tl_x=x
		tl_y=y-half_height
		br_x=x+w
		br_y=y+half_height
		
	elseif(direction==k_left) then
		tl_x=x-w
		tl_y=y-half_height
		br_x=x
		br_y=y+half_height
	
	elseif(direction==k_up) then
		tl_x=x-half_width
		tl_y=y-h
		br_x=x+half_width
		br_y=y
	
	
	elseif(direction==k_down) then
		tl_x=x-half_width
		tl_y=y
		br_x=x+half_width
		br_y=y+h	
	end
	
	--check if we extend out of bounds
	if(tl_x<0 or tl_y<0 or br_x>map_width or br_y>map_height) then return false end
	
	--check that there is space for this size
	for my=tl_y,br_y do
		for mx=tl_x,br_x do	
			if(sparse_mget(mx,my)!=0)then return false end
		end
	end
	

	
	--fill in floor
	for my=tl_y+1,br_y-1 do
		for mx=tl_x+1,br_x-1 do	
			sparse_mset(mx,my,16)
		end
	end
	
	--draw top edge
	for mx=tl_x+1,br_x-1 do
		sparse_mset(mx,tl_y,style+flr(rnd(k_vent_odds))*2)
		if(mx>tl_x+1 and mx<br_x-1 and rnd(1)<k_door_odds)then
			
			made_room=make_room(mx,tl_y-1,rand_size(),rand_size(),k_up,depth-1,style,tl_x,tl_y,br_x,br_y)
			if(made_room and rnd(1)<k_door_odds)then sparse_mset(mx,tl_y,36) sparse_mset(mx-1,tl_y,38)
			elseif(made_room)then sparse_mset(mx,tl_y,16) sparse_mset(mx-1,tl_y,16)end--cut door
		end
	end
	--draw bottom edge
	for mx=tl_x+1,br_x-1 do
		sparse_mset(mx,br_y,style+flr(rnd(k_vent_odds))*2)
		if(mx>tl_x+1 and mx<br_x-1 and rnd(1)<k_door_odds)then
			made_room=make_room(mx,br_y+1,rand_size(),rand_size(),k_down,depth-1,style,tl_x,tl_y,br_x,br_y)
			if(made_room and rnd(1)<k_door_odds)then sparse_mset(mx,br_y,36) sparse_mset(mx-1,br_y,38)
			elseif(made_room)then sparse_mset(mx,br_y,16) sparse_mset(mx-1,br_y,16) end
		end
	end
	--draw left edge
	for my=tl_y+1,br_y-1 do
		sparse_mset(tl_x,my,style+flr(rnd(k_vent_odds))*2)
		if(my>tl_y+1 and my<br_y-1 and rnd(1)<k_door_odds)then
			made_room=make_room(tl_x-1,my,rand_size(),rand_size(),k_left,depth-1,style,tl_x,tl_y,br_x,br_y)
			if(made_room and rnd(1)<k_door_odds)then sparse_mset(tl_x,my,37) sparse_mset(tl_x,my-1,39)
			elseif(made_room)then sparse_mset(tl_x,my,16) sparse_mset(tl_x,my-1,16) end
		end
	end
	--draw right edge
	for my=tl_y+1,br_y-1 do
		sparse_mset(br_x,my,style+flr(rnd(k_vent_odds))*2)
		if(my>tl_y+1 and my<br_y-1 and rnd(1)<k_door_odds)then
			made_room=make_room(br_x+1,my,rand_size(),rand_size(),k_right,depth-1,style,tl_x,tl_y,br_x,br_y)
			if(made_room and rnd(1)<k_door_odds)then sparse_mset(br_x,my,37) sparse_mset(br_x,my-1,39)
			elseif(made_room) then sparse_mset(br_x,my,16) sparse_mset(br_x,my-1,16)end
		end
	end
	
	--fill in the cornsers
 	sparse_mset(tl_x,tl_y,style)
	sparse_mset(br_x,br_y,style)
	sparse_mset(tl_x,br_y,style)
	sparse_mset(br_x,tl_y,style)
	

	--cut entry door
	if(not start_room) then
		
		if(direction==k_right) then sparse_mset(x,y,16) sparse_mset(x,y-1,16)	
		elseif(direction==k_left) then sparse_mset(x,y,16) sparse_mset(x,y-1,16)	
		elseif(direction==k_up) then  sparse_mset(x,y,16) sparse_mset(x-1,y,16)	
		elseif(direction==k_down) then sparse_mset(x,y,16) sparse_mset(x-1,y,16)	
		end
	end
		

	
		
		

	
	

	

	
	if( room_type==k_lobby_room) then
		sparse_mset(tl_x+2,tl_y+2,15)
		sparse_mset(tl_x+2,br_y-2,15)
		sparse_mset(br_x-2,tl_y+2,15)
		sparse_mset(br_x-2,br_y-2,15)
		
		sparse_mset(flr((tl_x+br_x)/2),flr((tl_y+br_y)/2),13)
		
	end
	
	if( room_type==k_dining_room) then
	
		sparse_mset(tl_x+2,tl_y+2,187)
		sparse_mset(tl_x+3,tl_y+2,138)
		sparse_mset(tl_x+4,tl_y+2,187)	

	end
	
	
	
	

	return true --we built a room!

end

elevator_map =	{{01,45,40,40,40,45,01},
					{45,00,00,00,00,00,01},
					{40,00,00,00,00,00,45},
					{43,00,00,00,00,00,39},
					{43,00,00,132,00,00,37},
					{40,00,00,00,00,00,45},
					{45,00,00,00,00,00,01},
					{01,45,40,40,40,45,01}}
					
starbeast_map = {{01,01,01,01,01,01,01,01,01,01,01,01,01,01,01,01,01,01},
				{01,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,01},
				{01,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,01},
				{01,16,16,16,16,16,16,16,16,16,16,16,16,16,45,16,16,01},
				{01,16,16,16,16,16,16,16,16,16,40,40,16,16,45,16,16,01},
				{01,16,16,16,16,16,16,16,16,16,40,40,16,16,16,16,16,01},
				{01,16,16,16,45,45,45,16,16,16,16,16,16,16,16,16,16,01},
				{01,16,16,16,45,16,45,16,16,16,16,16,16,16,16,16,16,01},
				{01,16,16,16,45,45,45,16,16,16,16,16,16,16,16,16,40,01},
				{01,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,40,01},
				{01,16,16,16,16,16,16,16,197,16,16,16,16,16,132,16,40,01},
				{01,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,40,01},
				{01,16,16,45,45,45,45,16,16,16,16,16,16,16,16,16,16,01},
				{01,16,16,45,45,45,45,16,16,16,16,16,16,16,16,16,16,01},
				{01,16,16,45,45,45,45,16,16,16,16,40,40,16,16,16,16,01},
				{01,16,16,45,45,45,45,16,16,16,16,40,40,16,16,16,16,01},
				{01,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,01},
				{01,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,01},
				{01,01,01,01,5,01,01,01,01,01,01,01,01,01,01,01,01,01}}
					
function	load_room(x,y,room)
	height=#room
	width=#room[1]
	
	for my=1,height do
		for mx=1,width do
			sparse_mset(mx+x,my+y,room[my][mx])
		end
	end
	
end

function	find_empty()
	valid=false
		--cycle randomly until we find a piece of empty floor
		--also make sure that it is 20 squares from the player
		while(valid==false)do
			mx=flr(rnd(map_width))
			my=flr(rnd(map_height))
			if(sparse_mget(mx,my)==16 and distance(player.x,player.y,mx,my)>25 )then valid=true end
		end
		return mx,my
end

function	load_item(the_type,number)
	for i=1,number do
		valid=false
		--cycle randomly until we find a piece of empty flor

			mx,my = find_empty()
			
			sparse_mset(mx,my,the_type)
	end
end



function	make_map()
	player.keycard=false

	if(player.floor==2)then
	load_room(0,0,starbeast_map)
	else
	load_room(10,10,elevator_map)
	

	make_room(18,14,10,10,k_right,k_start_depth,1)
	--cut open the wall next to the elevator
	sparse_mset(18,14,16) sparse_mset(18,15,16)
	
	--place keycard
	mx,my=find_empty()
	sparse_mset(mx,my,140)
	

	
	--load enemies
	load_item(64,2)
	load_item(69,2)
	load_item(74,2)
	load_item(101,2)
	load_item(96,2)
	
	--load treasure
	load_item(137,5)
	
	--load health
	load_item(136,2)
	end
	
--	make_room(rnd(map_width-max_room_size),rnd(map_height-max_room_size),rnd(max_room_size-min_room_size)+min_room_size,rnd(max_room_size-min_room_size)+min_room_size)

	
--make_room(flr(map_width/2),flr(map_height/2),10,10,k_right,k_start_depth,1)



end

function pause(t)
	--flip the screen and draw for t frames
	for i=0,t do flip() end
end


function sine_xshift(t,a,l,s,y1,y2,mode)
  for y=y1,y2 do
    local off = a * sin((y + flr(t*s + 0.5) + 0.5) / l)

    if mode and y%2 < 1 then off *= -1 end

    local x = flr(off/2 + 0.5) % 64

    local addr = 0x6000+64*y

    memcpy(0x4300,addr,64)
    memcpy(addr+x,0x4300,64-x)
    memcpy(addr,0x4340-x,x)
  end
end





door_list={}
function	new_door(mx,my,tile)
	d={}
	d.mx=mx
	d.my=my
	d.tile=tile
	d.closed=true
	d.opening=false
	d.closing=false
	d.open_percent=0
	add(door_list,d)
	return d
end


shot_list={}
function	new_shot(tile,x,y,vx,vy,life,player_shot)
	local p={}
	p.x=x
	p.y=y
	p.vx=vx
	p.vy=vy
	p.life=life
	p.player_shot=player_shot
	p.sprite = new_sprite(tile,x,y,1,1,.2)
	add(shot_list,p)
	return p
end

function	update_shot_list()
	for the_shot in all(shot_list)
	do
		
		
		--check for actor hits
		--for enemy in all(enemy_list) do
		--	if( distance(the_shot.x,the_shot.y,enemy.x,enemy.y)<1) then
		--	enemy.life-=26
		--	the_shot.life=0
		--	new_particle(95,the_shot.x,the_shot.y,1,1,0,0,10)
		--	end
		--end
		
		if( fget(mget(the_shot.x+the_shot.vx,the_shot.y+the_shot.vy),2)  )then the_shot.life=0 new_particle(95,the_shot.x,the_shot.y,1,1,0,0,10) end
		
		the_shot.x+=the_shot.vx
		the_shot.y+=the_shot.vy
		the_shot.life-=1
		the_shot.sprite.x=the_shot.x
		the_shot.sprite.y=the_shot.y
		
		if(the_shot.life<=0)then del(sprite_list,the_shot.sprite) del(shot_list,the_shot) end
		
		if(distance(the_shot.x,the_shot.y,player.x,player.y)<.5)then player.life-=10 player.damage=true the_shot.life=0 end
	
		
	end
end


particle_list={}
k_gravity = .2
k_max_particles = 80

function	new_particle(tile,x,y,tile_w,tile_h,vx,vy,life)
	local p={}
	p.x=x
	p.y=y
	p.vx=vx
	p.vy=vy
	p.life=life
	p.sprite = new_sprite(tile,x,y,tile_w,tile_h)
	add(particle_list,p)
	return p
end

function	update_particle_list()
	for the_particle in all(particle_list)
	do
		the_particle.x+=the_particle.vx
		the_particle.y+=the_particle.vy
		the_particle.life-=1
		the_particle.sprite.x=the_particle.x
		the_particle.sprite.y=the_particle.y
		
		if(the_particle.life<=0)then del(sprite_list,the_particle.sprite) del(particle_list,the_particle) end
	end
end





sprite_list={}
sprite_count=0




function new_sprite(tile,x,y,tile_w,tile_h,v_move)
	a={}
	a.x=x
	a.y=y
	
	a.px=0
	a.py=0

	a.tile=tile
	a.tile_w=tile_w
	a.tile_h=tile_h
	a.sort=0
	
	if(v_move)then a.v_move=v_move else a.v_move=0 end
	
--	a.sx=tile%16*8
--	a.sy=flr(tile/16)*8
	
	a.cylinder=true
	a.direction=.25
	a.parent=false

	--sprite_list[sprite_count]=a
	--sprite_count+=1

	
	add(sprite_list,a)
	
	
	return a

end

dir_x = -1 --initial direction vector
dir_y = 0 

player={}
function init_player()
	player.x=8
	player.y=8
	player.vx=0
	player.vy=0
	player.collide=false
	player.direction = atan2(dir_x,dir_y)
	player.cooldown_timer=0
	player.life=100
	player.speed=.25
	player.rot_speed=.01
	player.damage=false
	player.score=0
	player.keycard=false
	player.floor=0
	player.starbeast_dead=false
end




enemy_list={}
function new_enemy(x,y,tile,ai,cylinder,width)
	b={}
	
	
	
	if(width)then b.width=width else b.width=1 end
	b.sprite=new_sprite(tile,x,y,b.width,2)
	if(cylinder)then b.sprite.cylinder = true  else b.sprite.cylinder=false end
	b.sprite.parent=b
	b.direction=.75
	b.sprite.direction=b.direction
	b.x=x
	b.y=y
	b.vx=0
	b.vy=0
	b.collide=false
	b.speed=.1
	b.ai=ai
	b.enemy=true
	
	
	
	b.cooldown_timer=15
	

	b.ai_timer=0
	b.ai_state=0
	b.target_direction=.5
	b.life=100
	add(enemy_list,b)
	return b
end



function cast_view()
frame+=1

	for x=screen_start_x, screen_width, pix_width do

		camera_x = 1 - (2*x) / h_res
		ray_dir_x = dir_x + plane_x * camera_x
		ray_dir_y = dir_y + plane_y * camera_x
		
		--which box of the map we are in
		map_x = flr(player.x)
		map_y = flr(player.y)
		
		--length of ray from current position to next x or y intersect		
		if(abs(ray_dir_x)<.01) then delta_dist_x=999 else --some trickery because of acuracy
		delta_dist_x = sqrt(1+(ray_dir_y * ray_dir_y) / (ray_dir_x * ray_dir_x))
		end
		if(abs(ray_dir_y)<.01) then delta_dist_y=999 else
		delta_dist_y = sqrt(1+(ray_dir_x * ray_dir_x) / (ray_dir_y * ray_dir_y))
		end
		
		--what direction to step in		
		hit = 0 --was there a wall hit
		
		-- calculate step and initial side_dist
		if(ray_dir_x < 0) then
			step_x = -1
			side_dist_x = (player.x -map_x) * delta_dist_x
		else
			step_x = 1
			side_dist_x = (map_x + 1 - player.x ) * delta_dist_x
		end
		
		if(ray_dir_y < 0)then
			step_y = -1
			side_dist_y = (player.y - map_y) * delta_dist_y
		else
			step_y = 1
			side_dist_y = (map_y + 1 - player.y) * delta_dist_y
		end
		
		--perform dda
		cyc = 0		
		while (hit == 0 and cyc<view_dist) do	
			cyc+=1		
			--jump to next map square or in x-dir or in y-dir
			if(side_dist_x < side_dist_y) then
				side_dist_x += delta_dist_x
				map_x += step_x
				side = 0
			else
				side_dist_y += delta_dist_y
				map_y += step_y
				side = 1
			end		
			--check if a ray has hit a wall
			tex_num = mget(map_x,map_y)
			is_wall=fget(tex_num,0)
			is_door_left=fget(tex_num,4)
			is_door_right=fget(tex_num,5)
			if( is_wall or cyc>(view_dist-1)) then		
				if(is_wall) then hit=1 end-- pset(map_x*8,map_y*8,9)			
				--find texture
				if(side==1) then
					wall_x = player.x + ((map_y-player.y+(1-step_y)/2)/ray_dir_y)* ray_dir_x
				else
					wall_x = player.y + ((map_x-player.x+(1-step_x)/2) /ray_dir_x)* ray_dir_y
				end
				
				wall_x -=flr((wall_x))

				
				
				
				
				if(is_door_left or is_door_right)then
					the_door=find_door(map_x,map_y)
					
					
					
						if( tex_num%2==0 and side==1) then --only worry about doors opening to the east
							if(is_door_left)then
								tex_x = flr(wall_x * tex_width)+tex_num%16*tex_width + the_door.open_percent*tex_width
								if(wall_x>= 1-the_door.open_percent or wall_x<.05)then hit=0 end
								
										if(the_door.open_percent<=0)then	
										hit=1
										tex_x = flr(wall_x * tex_width)+tex_num%16*tex_width
										end
								
							else --door=r=ight
								tex_x = flr(wall_x * tex_width)+tex_num%16*tex_width -flr(the_door.open_percent*tex_width)
								if(wall_x<= the_door.open_percent or wall_x>.95)then hit=0 end
								
										
										if(the_door.open_percent<=0)then	
										hit=1
										tex_x = flr(wall_x * tex_width)+tex_num%16*tex_width
										end

								
							end
						elseif( tex_num%2==1 and side==0) then --only worry about doors opening to the east
							if(is_door_left)then
								tex_x = flr(wall_x * tex_width)+tex_num%16*tex_width + the_door.open_percent*tex_width
								if(wall_x>= 1-the_door.open_percent or wall_x<.05)then hit=0 end
								
								
										if(the_door.open_percent<=0)then	
										hit=1
										tex_x = flr(wall_x * tex_width)+tex_num%16*tex_width
										end
										
							else --door=r=ight
								tex_x = flr(wall_x * tex_width)+tex_num%16*tex_width -the_door.open_percent*tex_width
								if(wall_x<= the_door.open_percent+.1 or wall_x>.95)then hit=0 end
								
										if(the_door.open_percent<=0)then	
										hit=1
										tex_x = flr(wall_x * tex_width)+tex_num%16*tex_width
										end

								
							end
						else
							hit=0
						end
						
						
				
				else --normal wall
					tex_x = flr(wall_x * tex_width)+tex_num%16*tex_width+side*tex_width
				end
				
			
				
				tex_y = flr(tex_num/16)*8
				
				
				--calculate distance projected on camera dir
				if(side==0) then
					perp_wall_dist = abs((map_x -player.x + (1 - step_x)/2 ) / ray_dir_x)
				else
					perp_wall_dist = abs((map_y - player.y + (1-step_y) /2) / ray_dir_y)
				end
				
				line_height = abs( flr( h / perp_wall_dist))/2*y_scale
				floor_y = 64+line_height
			 end
		end
		
		if(hit==1) then
				tex_shift=0
				sub_tex_height=tex_height
								
				if(line_height<64 ) then
					sspr(tex_x,tex_y,1,tex_height*2,x,64-line_height,pix_width,line_height*2)
				else
					sub_tex_height=tex_height*64/line_height
					line_height=64
					tex_shift=tex_height-sub_tex_height
					sspr(tex_x,tex_y+tex_shift,1,sub_tex_height*2,x,64-line_height,pix_width,line_height*2)
				
				end
				
				--if(wall_x>.8)then rectfill(x,64-line_height,x,64+line_height,14) end

		end

		z_buffer[flr(x)] = perp_wall_dist	
	end	
end






--this function makes the walls block sprites
function draw_sprite(sprite)
	sprite_x=sprite.x-player.x
	sprite_y=sprite.y-player.y
	
	--work
	
	--transform sprite_position with the camera matrix
	inv_det = 1/(plane_x*dir_y-dir_x*plane_y)
	
	
	
	transform_x = -inv_det * (dir_y * sprite_x - dir_x * sprite_y)
	transform_y = inv_det * (-plane_y * sprite_x + plane_x * sprite_y)
	
	sprite.px=transform_x
	sprite.py=transform_y
	
	if(transform_y<.5 or transform_y>15)then return false end
	
	
	
	sprite_screen_x = flr((w/2) * (1+transform_x /transform_y))
	
	u_div = 2
	v_div = 2
	v_move =sprite.v_move*64
	v_move_screen = flr(v_move/transform_y)
	
	--calculate the height of the sprite on the screen
      sprite_height = abs(flr(h / (transform_y))) / v_div * sprite.tile_h * y_scale--using "transformy" instead of the real distance prevents fisheye
     --calculate lowest and highest pixel to fill in current stripe
      draw_start_y = -sprite_height / 2 + h / 2 + v_move_screen
      if(draw_start_y < 0) then draw_start_y = 0 end
      draw_end_y = sprite_height / 2 + h / 2 + v_move_screen
      if(draw_end_y >= h) then draw_end_y = h - 1 end
	  
	  sprite_width = abs( flr (h / (transform_y))) / u_div * sprite.tile_w*y_scale
      draw_start_x = flr( -sprite_width / 2 + sprite_screen_x )
	  if(draw_start_x%pix_width==0)then draw_start_x+=1  end
	  
      if(draw_start_x < screen_start_x+pix_width) then draw_start_x = screen_start_x+2+pix_width end
      draw_end_x = flr(sprite_width / 2 + sprite_screen_x)
      if(draw_end_x >= screen_width -pix_width) then draw_end_x = screen_width - 2 - pix_width end
	  
	
		sx=sprite.tile%16*8
		sy=flr(sprite.tile/16)*8
		sw=sprite.tile_w*8
		sh=sprite.tile_h*8
	  
	  
	  for stripe=draw_start_x, draw_end_x, pix_width do
	  
		--stripe = flr( mid(stripe,20,120) )
		tex_x = flr((stripe - (-sprite_width / 2 + sprite_screen_x)) * sprite.tile_w*8 / sprite_width) 
		
		
		--handle sprite_angle
		if(sprite.cylinder==false)then
			--delta_direction = ( sprite.direction - player.direction ) % 1	
			delta_direction = (( player.direction - sprite.direction )+.5) % 1	
			if(delta_direction<0)then delta_direction+=1 end
			if(delta_direction<=.625 ) then
				spr_shift = flr(delta_direction*8) * sw
				spr_flip=false
			elseif(delta_direction>.9) then
				spr_shift = 0
				spr_flip=false
			else
				spr_shift = flr((1-delta_direction)*8+1) * 8
				spr_flip=true
			end
		end
		
		
		
			if(transform_y > 0 and stripe > 0 and stripe < w and transform_y < z_buffer[stripe]  ) then -- and 
				
				
				if(sprite.cylinder) then
					sspr(sx+mid(tex_x,0,sw-1),sy,1,sprite.tile_h*8,stripe,draw_start_y,pix_width, -(draw_start_y-draw_end_y) )
				else
					if(spr_flip) then
						sspr(sx+spr_shift+sw-mid(tex_x,0,sw-1)-1,sy,1,sprite.tile_h*8,stripe,draw_start_y,pix_width, -(draw_start_y-draw_end_y) )
					else
						sspr(sx+spr_shift+mid(tex_x,0,sw-1),sy,1,sprite.tile_h*8,stripe,draw_start_y,pix_width, -(draw_start_y-draw_end_y) )
					end
				end
				
				--store nearest enemy that is visible
				if(stripe>62 and stripe<64)then
					parent=sprite.parent
					if(parent!=false)then
						center_target=parent
						--rectfill(stripe,draw_start_y,stripe+1,draw_end_y,8)
					end
				end
				
			end
		
		
		
	  end
	  

	  
	
	
end



function get_map_pix(x,y)
	local tile_number = mget(shr(x,3), shr(y,3))

	local tile_y = band(shr(tile_number,1),0xfff8)+y%8
	local tile_x = shl(tile_number%16,3)+x%8

	return sget(tile_x,tile_y) 
end





function	draw_map()
	for j=0,20 do
		for i=0,20 do
			spr(mget(i,j),i*8,j*8)
		end
	end
	
	circ(player.x*8,player.y*8,2,7)
	line(player.x*8,player.y*8, (player.x+dir_x)*8, (player.y+dir_y)*8,7)
	
end

--use the number tiles starting at font
--to print a number at x,y
--using this for score so add a fake 0
function	draw_number(font,num,x,y)
	
	--bummer is that numbers are limited in size to 32767 so we fake it
	--how many digits?
	digits=0
	remain=num
	if(num!=0)then
		while remain>0 do
			remain=flr(remain/10)
			digits+=1
		end
	else spr(font,x+(digits)*8,y) return 0 end -- 0 has one digit
	
	remain=num
	for i=1, digits do
		val = flr(remain%10)
		remain=flr(remain/10)
		spr(font+val,x+(digits-i)*8,y)
	end
	
	
		spr(font,x+(digits)*8,y)
	
	
	
	
	
	
	

end


function	handle_buttons()

	player.vx=0
	player.vy=0
	
	if(btn(1))then --player.direction+=.02 
	
		if(btn(5))then --strafe
		
			player.vx+=cos(player.direction-.25)*player.speed
			player.vy+=sin(player.direction-.25)*player.speed
		
			else
			old_dir_x = dir_x
			dir_x = dir_x * cos(-player.rot_speed) - dir_y * sin(-player.rot_speed)
			dir_y = old_dir_x * sin(-player.rot_speed) + dir_y * cos(-player.rot_speed)
			old_plane_x = plane_x
			plane_x = plane_x * cos(-player.rot_speed) - plane_y * sin(-player.rot_speed)
			plane_y = old_plane_x * sin(-player.rot_speed) + plane_y * cos(-player.rot_speed)
		end
	
	
	end
	if(btn(0))then --player.direction+=-.02 
	
		if(btn(5))then --strafe
			
			player.vx+=cos(player.direction+.25)*player.speed
			player.vy+=sin(player.direction+.25)*player.speed
			
			else
	
			old_dir_x = dir_x
			dir_x = dir_x * cos(player.rot_speed) - dir_y * sin(player.rot_speed)
			dir_y = old_dir_x * sin(player.rot_speed) + dir_y * cos(player.rot_speed)
			old_plane_x = plane_x
			plane_x = plane_x * cos(player.rot_speed) - plane_y * sin(player.rot_speed)
			plane_y = old_plane_x * sin(player.rot_speed) + plane_y * cos(player.rot_speed)
		end
	
	end
	
	player.direction=(atan2(dir_x,dir_y))
	

		
	if(btn(2))then player.vx =dir_x*player.speed player.vy=dir_y*player.speed end
	if(btn(3))then player.vx=-dir_x*player.speed player.vy=-dir_y*player.speed end
	
	
	
	--handle shot
	
	if(player.cooldown_timer<=0)then player.cooldown_timer=0 end --correct for negative overflow
	
	if(btn(4))then
	
		--check if we are at a terminal
		mx=player.x+dir_x*2
		my=player.y+dir_y*2
		tile1=mget(mx,my)
		mx=player.x+dir_x*1
		my=player.y+dir_y*1
		tile2=mget(mx,my)
		if(tile1==43 or tile2==43)then
		
			if(#enemy_list>0 or player.keycard==false)then
			long_string="to exit level, you must destroy remaining "..#enemy_list.." enemies and collect the key...        -eom-   "
			print_message(long_string)
			else
				long_string="you have completed floor "..player.floor .." prepare for the    next floor......................................"
				print_message(long_string)
				new_floor()
			end
		else
			handle_player_shot()
		end
	end
	
	

	--if(btn(4,1))then
	--	new_floor()
	--end
	
	player.direction%=1
	player.cooldown_timer-=1
end


function	handle_player_shot()




	if(player.cooldown_timer<=0) then
			sfx(k_sound_player_shot)
			player.cooldown_timer=10
			
			if(center_target.life!=nil)then
				center_target.life-=35
				--sfx(k_sound_enemy_damage)
				vx,vy=normalize_distance(player.x,player.y,center_target.x,center_target.y)
				--center_target.vx-=vx*.5
				--center_target.vy-=vy*.5
				
				dist=.25
			--	new_particle(136,center_target.x-dir_x*dist*1.2,center_target.y-dir_y*dist*1.2,1,1,0,0,20)
				new_particle(135,center_target.x-dir_x*dist,center_target.y-dir_y*dist,1,1,0,0,10)
				
			
			else
			dist=z_buffer[63]-.25
			new_particle(134,player.x+dir_x*dist,player.y+dir_y*dist,1,1,0,0,100)--z_buffer[64]
			end
			
		end

end


function	normalize_distance(x1,y1,x2,y2)
	l= sqrt ( (x1-x2)*(x1-x2) + (y1-y2)*(y1-y2) )
	x3=(x1-x2)/l
	y3=(y1-y2)/l
	return x3, y3
end

function	update_actor(actor)
	actor.collide=false

	offset=.4
	if(fget(mget(actor.x+offset+actor.vx,actor.y+offset),2) or fget(mget(actor.x-offset+actor.vx,actor.y+offset),2) or fget(mget(actor.x+actor.vx+offset,actor.y-offset),2) or fget(mget(actor.x+actor.vx-offset,actor.y-offset),2))then actor.vx=0 actor.collide=true end
	actor.x+=actor.vx
	if(fget(mget(actor.x+offset,actor.y+offset+actor.vy),2) or fget(mget(actor.x-offset,actor.y+actor.vy+offset),2) or fget(mget(actor.x+offset,actor.y+actor.vy-offset),2) or fget(mget(actor.x-offset,actor.y+actor.vy-offset),2))then actor.vy=0 actor.collide=true end
	actor.y+=actor.vy
	
	if(actor.sprite) then
		actor.sprite.x=actor.x
		actor.sprite.y=actor.y
		actor.sprite.direction=actor.direction
	end
	
	if(actor.life<0 and actor!=player)then
		enemy_explode(actor)
		player.score+=5
		
		if(actor.ai==handle_starbeast_ai)then player.starbeast_dead=true end
	end
	
	--tile=fget(actor.x,actor.y) 
	--check for doors and open them
	--if(tile==36 or tile==37 or tile==38 or tile==39) then
	--	the_door=find_door(flr(actor.x),flr(actor.y))
	--	if(the_door!=nil)then the_door.opening=true end
	--end
	
	
end

function	direction_from_vector(x1,y1,x2,y2)
	d=(atan2( x1-x2,y1-y2))
	if d<0 then d+=1 end
	return d
end


function	distance(x1,y1,x2,y2)
	return( abs(x1-x2)+abs(y1-y2))
end

k_shot_speed=.2
k_cool_down = 45
function	handle_turret_ai(actor)
	actor.speed=0
	
	dist=distance(actor.x,actor.y,player.x,player.y)
	
	
	if(dist<10)then
		
			way_angle=direction_from_vector(player.x,player.y,actor.x,actor.y)-actor.direction
			if(way_angle>0.5) then way_angle= -(1-way_angle) end 
			if(way_angle<-0.5) then way_angle= -(1+way_angle) end 
			
			if( way_angle>.01 )then actor.direction+=.005 
			elseif( way_angle<-.01 )then actor.direction+=-.005 
			else
				
				--centered
				--new_shot(tile,x,y,vx,vy,life,player_shot)
				if(actor.ai_timer<=0)then
				new_shot(79,actor.x,actor.y,cos(actor.direction)*k_shot_speed,sin(actor.direction)*k_shot_speed,50,false)
				actor.ai_timer=k_cool_down
				end
			end
	end
	

	--actor.vx=cos(actor.direction)*actor.speed
	--actor.vy=sin(actor.direction)*actor.speed
	
	actor.direction%=1
	
		
		
	actor.ai_timer-=1
	if(actor.ai_timer<=0)then actor.ai_timer=0 end

end


function	handle_rover_ai(actor)
	actor.speed=.03
	
	dist=distance(actor.x,actor.y,player.x,player.y)
	
	--if(mget(actor.x+vx,actor.y+vy)!=16)then actor.collide=true end
	
	if(actor.collide or dist<1.5)then
	
	actor.ai_timer=45
	actor.ai_state=1


	actor.collide=false
	end
	
	if(actor.ai_timer>25 ) then
		actor.speed=-.02
		actor.ai_timer-=1
	elseif(actor.ai_timer>0 ) then
		actor.speed=0
		actor.direction+=.02
		actor.ai_timer-=1
	else
		actor.ai_state=0
	end
		
	if(actor.ai_state==0)then
		if(dist<8)then
		
			way_angle=direction_from_vector(player.x,player.y,actor.x,actor.y)-actor.direction
			if(way_angle>0.5) then way_angle= -(1-way_angle) end 
			if(way_angle<-0.5) then way_angle= -(1+way_angle) end 
			
			if( way_angle>.02 )then actor.direction+=.02 
			elseif( way_angle<-.02 )then actor.direction+=-.02 
			
			else
			actor.speed=.08
			end
			
		end
	end

	actor.vx=cos(actor.direction)*actor.speed
	actor.vy=sin(actor.direction)*actor.speed
	
	actor.direction%=1
	
		if(distance(actor.x,actor.y,player.x,player.y)<1.75) then
			player.damage=true
			player.life-=3
		end

end

function	handle_seaker_ai(actor)
	actor.speed=.08
	
	dist=distance(actor.x,actor.y,player.x,player.y)
	
	--if(mget(actor.x+vx,actor.y+vy)!=16)then actor.collide=true end
	

		if(dist<20)then
		
			way_angle=direction_from_vector(player.x,player.y,actor.x,actor.y)-actor.direction
			if(way_angle>0.5) then way_angle= -(1-way_angle) end 
			if(way_angle<-0.5) then way_angle= -(1+way_angle) end 
			
			if( way_angle>.02 )then actor.direction+=.02 
			elseif( way_angle<-.02 )then actor.direction+=-.02 
			else
			actor.speed=.08
			end
		end


	actor.vx=cos(actor.direction)*actor.speed
	actor.vy=sin(actor.direction)*actor.speed
	
	actor.direction%=1
	
		if(distance(actor.x,actor.y,player.x,player.y)<1.75) then
			player.damage=true
			player.life-=.5
		end

end

function	handle_gunner_ai(actor)
	actor.speed=.03
	
	dist=distance(actor.x,actor.y,player.x,player.y)
	
	--if(mget(actor.x+vx,actor.y+vy)!=16)then actor.collide=true end
	

		if(dist<15)then
		
			way_angle=direction_from_vector(player.x,player.y,actor.x,actor.y)-actor.direction
			if(way_angle>0.5) then way_angle= -(1-way_angle) end 
			if(way_angle<-0.5) then way_angle= -(1+way_angle) end 
			
			if( way_angle>.01 )then actor.direction+=.005 
			elseif( way_angle<-.01 )then actor.direction+=-.005 
			else
				
				--centered
				--new_shot(tile,x,y,vx,vy,life,player_shot)
				if(actor.ai_timer<=0)then
				sfx(k_sound_enemy_shot)
				new_shot(79,actor.x,actor.y,cos(actor.direction)*k_shot_speed,sin(actor.direction)*k_shot_speed,50,false)
				actor.ai_timer=k_cool_down
				end
			end
		end


	actor.vx=cos(actor.direction)*actor.speed
	actor.vy=sin(actor.direction)*actor.speed
	
	actor.direction%=1
	
		if(distance(actor.x,actor.y,player.x,player.y)<1.75) then
			player.damage=true
			player.life-=.5
		end
		
		actor.ai_timer-=1
		if(actor.ai_timer<=0)then actor.ai_timer=0 end

end

function	handle_master_ai(actor)
	actor.speed=.02
	
	dist=distance(actor.x,actor.y,player.x,player.y)
	
	--if(mget(actor.x+vx,actor.y+vy)!=16)then actor.collide=true end
	

		if(dist<15)then
		
			way_angle=direction_from_vector(player.x,player.y,actor.x,actor.y)-actor.direction
			if(way_angle>0.5) then way_angle= -(1-way_angle) end 
			if(way_angle<-0.5) then way_angle= -(1+way_angle) end 
			
			if( way_angle>.01 )then actor.direction+=.005 
			elseif( way_angle<-.01 )then actor.direction+=-.005 
			else
				
				--centered
				--new_shot(tile,x,y,vx,vy,life,player_shot)
				if(actor.ai_timer<=0)then
				sfx(k_sound_enemy_shot)
				new_shot(79,actor.x,actor.y,cos(actor.direction+.03)*k_shot_speed,sin(actor.direction+.03)*k_shot_speed,50,false)
				new_shot(79,actor.x,actor.y,cos(actor.direction)*k_shot_speed,sin(actor.direction)*k_shot_speed,50,false)
				new_shot(79,actor.x,actor.y,cos(actor.direction-.03)*k_shot_speed,sin(actor.direction-.03)*k_shot_speed,50,false)
				actor.ai_timer=k_cool_down
				end
			end
		end


	actor.vx=cos(actor.direction)*actor.speed
	actor.vy=sin(actor.direction)*actor.speed
	
	actor.direction%=1
	
		if(distance(actor.x,actor.y,player.x,player.y)<1.75) then
			player.damage=true
			player.life-=.5
		end
		
		actor.ai_timer-=1
		if(actor.ai_timer<=0)then actor.ai_timer=0 end

end

k_spawn_time = 100
spawn_time =  k_spawn_time
function	handle_starbeast_ai(actor)
	actor.speed=.04
	
	dist=distance(actor.x,actor.y,player.x,player.y)
	
	--if(mget(actor.x+vx,actor.y+vy)!=16)then actor.collide=true end
	

		if(dist<20)then
		
			way_angle=direction_from_vector(player.x,player.y,actor.x,actor.y)-actor.direction
			if(way_angle>0.5) then way_angle= -(1-way_angle) end 
			if(way_angle<-0.5) then way_angle= -(1+way_angle) end 
			
			if( way_angle>.01 )then actor.direction+=.005 
			elseif( way_angle<-.01 )then actor.direction+=-.005 
			else
				
				--centered
				--new_shot(tile,x,y,vx,vy,life,player_shot)
				if(actor.ai_timer<=0)then
				sfx(k_sound_enemy_shot)
				new_shot(229,actor.x,actor.y,cos(actor.direction+.03)*k_shot_speed,sin(actor.direction+.03)*k_shot_speed,50,false)
				new_shot(229,actor.x,actor.y,cos(actor.direction)*k_shot_speed,sin(actor.direction)*k_shot_speed,50,false)
				new_shot(229,actor.x,actor.y,cos(actor.direction-.03)*k_shot_speed,sin(actor.direction-.03)*k_shot_speed,50,false)
				actor.ai_timer=18
				end
			end
		end


	actor.vx=cos(actor.direction)*actor.speed
	actor.vy=sin(actor.direction)*actor.speed
	
	actor.direction%=1
	
		if(distance(actor.x,actor.y,player.x,player.y)<1.75) then
			player.damage=true
			player.life-=.8
		end
		
		if(spawn_time<=0)then
			new_x =flr(actor.x+rnd(10)-5)
			new_y = flr(actor.y+rnd(10)-5)
			if(mget(new_x,new_y)==16)then
				new_enemy(new_x,new_y,69,handle_seaker_ai)
				new_particle(199,new_x,new_y,1,2,0,0,20)
				sfx(7)
				spawn_time=k_spawn_time
			end
		end
		
		actor.ai_timer-=1
		if(actor.ai_timer<=0)then actor.ai_timer=0 end
		
		spawn_time-=1
		if(spawn_time<=0)then spawn_time=0 end

end


function update_enemies()
	for enemy in all(enemy_list) do
			update_actor(enemy)
			enemy.ai(enemy)

	end
end

function	enemy_explode(actor)
	
	sfx(k_sound_enemy_explode)
	explode_speed=.1
	for explode_angle=0,1, .25 do
	new_particle(42,actor.x,actor.y,1,2,cos(explode_angle)*explode_speed,sin(explode_angle)*explode_speed,20)
	end
	
	del(sprite_list,actor.sprite)
	del(enemy_list,actor)

end

function	update_doors()
	for door in all(door_list) do
		if(door.opening) then
			
			if(door.open_percent<1) then
				if(door.open_percent==0)then sfx(k_sound_door) end
				door.open_percent+=.05
			end
			if(door.open_percent>=1) then
				door.open_percent=1
				door.closed=false
				door.opening=false
				door.closing=false
				end
		elseif(door.closing) then
			--if(door.open_percent==1)then sfx(k_sound_door) end
			if(door.open_percent>0) then door.open_percent-=.05 end
			if(door.open_percent<=0) then
				door.open_percent=0
				door.closed=true
				door.opening=false
				door.closing=false
				end
		end
		
		if(distance(door.mx,door.my,player.x,player.y)<15)then

			if(distance(door.mx,door.my,player.x,player.y)<5) then door.opening=true door.closing=false
			else door.closing=true door.opening=false end
		
			--only worry about opening doors for enemies if the player is near them		
			for enemy in all(enemy_list) do
				if(distance(door.mx,door.my,enemy.x,enemy.y)<3) then door.opening=true door.closing=false end
			end
		end
	
	end

end

function	find_door(mx,my)
	for door in all(door_list) do
		if(door.mx==flr(mx) and door.my==flr(my) )then 
		
		--print("found!",60,60,7)
		--flip()
		
		return door end
	end
	return false


end

function	find_sprite(tile,mx,my)
	for sprite in all(sprite_list) do
		if(flr(sprite.x)==mx and flr(sprite.y)==my and sprite.tile==tile)then 
		
		--print("found!",60,60,7)
		--flip()

		return sprite end
	end
	return false
end


function	scan_map()
	for my=0,map_height do
		for mx=0,map_width do
			tile = mget(mx,my)
			if(fget(tile,1)) then --sprites
			
				if(fget(tile,6))then --floor sprite
					new_sprite(tile,mx+.5,my+.5,1,1,1)
				else --default to 1x2 sprite
				new_sprite(tile,mx+.5,my+.5,1,2)
				end
			elseif(fget(tile,3)) then --enemies
			
				if(tile==64)then
					new_enemy(mx+.5,my+.5,tile,handle_rover_ai)
				elseif(tile==69)then
					new_enemy(mx+.5,my+.5,tile,handle_seaker_ai)
				elseif(tile==74)then
					new_enemy(mx+.5,my+.5,tile,handle_turret_ai)
				elseif(tile==96)then
					new_enemy(mx+.5,my+.5,tile,handle_master_ai)
				elseif(tile==101)then
					new_enemy(mx+.5,my+.5,tile,handle_gunner_ai)
				elseif(tile==197)then
				--star beast
					beast = new_enemy(mx+.5,my+.5,tile,handle_starbeast_ai,true,2)
					beast.life=400
				end 
					
				mset(mx,my,0)
			
			elseif(fget(tile,5) or fget(tile,4)) then --door
				new_door(mx,my,tile)
			

			end
			
			if(tile==132)then
				player.x=mx+.5
				player.y=my+.5
				mset(mx,my,0)
			end
		end
	end
end

sprite_order={}
sprite_distance={}
function draw_sprites()
	
	center_target={} -- clear the center target
	--the draw sprite function will store the new center target
	
	for sprite in all(sprite_list) do
		sprite.sort = (sprite.x-player.x)*(sprite.x-player.x)+(sprite.y-player.y)*(sprite.y-player.y)
		--sprite.sort = abs(sprite.x-player.x)+abs(sprite.y-player.y)
	end
	sort_sprites(sprite_list)
	
	for sprite in all(sprite_list) do
		draw_sprite(sprite)
	end
	
	--print(#sprite_list,50,50,7)
	
	
	
	
	
end

function sort_sprites(a)
  for i=1,#a do
     j = i
    while j > 1 and a[j-1].sort < a[j].sort do
      a[j],a[j-1] = a[j-1],a[j]
      j = j - 1
    end
  end
end

function	draw_gun()
	--spr(108,64-8,90,2,2)
	--if(player.cooldown_timer>=9)then
	--	new_canvas_particle(44,64,64,0,0,0,20)
	if(player.cooldown_timer>8)then
	icon=108
		
		
	
	elseif(player.cooldown_timer>3)then
	--	for i=0 ,2 do
		--new_canvas_particle(43,64,88,rnd(2)-1,0,-rnd(.1),20)
		--end
	
	icon=110
	else
	icon=106
	end
	
	--hole_height = abs( flr( h / z_buffer[63]))/2*y_scale
	--hole_x=128
	--shot_tile=134
	--sspr(shot_tile%16*8,flr(shot_tile/16)*8,8,8,64-hole_height/2,64-hole_height/2,hole_height,hole_height)
	
	
	sspr(icon%16*8,flr(icon/16)*8,16,16,64-16,75+mid(player.cooldown_timer,0,10)/3,32,32)

end

function	check_player()
	mx = flr(player.x)
	my = flr(player.y)
	tile=mget(mx,my)
	
	

	--check for health
	if(tile==136 and player.life<100) then
		sfx(k_sound_pickup)
		player.life+=10
		if(player.life>100)then player.life=100 end
		mset(mx,my,0)
		the_health = find_sprite(136,mx,my)
		if(the_health)then del(sprite_list, the_health) end	
	end
	
	--check for coins
	if(tile==137) then
		sfx(k_sound_pickup)
		player.score+=10
		mset(mx,my,0)
		the_coin = find_sprite(137,mx,my)
		if(the_coin)then del(sprite_list, the_coin) end	
	end
	
	--check for keycard
	if(tile==140) then
		sfx(k_sound_pickup)
		player.keycard=true
		mset(mx,my,0)
		
		the_card = find_sprite(140,mx,my)
		if(the_card)then del(sprite_list, the_card) end	
	end

	if(player.life<0)then
		sfx(k_sound_enemy_explode )
		game_over()
	end

end

function	draw_hud()
	
	health_width=50
	
	spr(160,0,106)
	spr(176,0,114)
	
	spr(162,120,106)
	spr(178,120,114)
	
	for x=8,112,8 do
		spr(161,x,106)
		spr(177,x,114)
	end
	
	--draw_life
	spr(163,4,107)
	sspr(164%16*8,flr(164/16)*8,8,8,12,107,max(player.life,0)/100*health_width,8)
	spr(165,12+max(player.life,0)/100*health_width,107)
	
	--draw_score
	
	spr(158,68,108)
	draw_number(148,player.score,76,108)
	
	floor_text = "floor "..player.floor
	print(floor_text,8,115,5)
	print(floor_text,9,115,7)
	
	if(player.keycard)then
		spr(140,118,112)
	end

end

function	show_damage()
	if(player.damage==true)then
	sfx(k_sound_player_damage)
	sine_xshift(frame,5,10,1,0,120,n)
	end
end

function delete_enemies()
	for enemy in all(enemy_list) do
		del(enemy_list,enemy)
	end
end

function delete_sprites()
	for sprite in all(sprite_list) do
		del(sprite_list,sprite)
	end
end

function delete_doors()
	for door in all(door_list) do
		del(door_list,door)
	end
end

function delete_sparse_map()
	for my=1,#sparse_map do
		if(sparse_map[my]!=nil)then del(sparse_map[my]) end
	end
	

end

function new_floor()
	delete_enemies()
	delete_sprites()
	delete_doors()
	delete_sparse_map()
	init_sparse_map()
	make_map()
	scan_map()
	
	player.floor+=1
	
end

function	draw_radar()
		circfill(110+8,8+17,8,0)
		
	for enemy in all(enemy_list) do
		x=(enemy.sprite.px/4)
		y=-(enemy.sprite.py/4)
		
		--x=mid(x,0,15)
		--y=mid(y,0,15)
		
		if(x*x+y*y<49)then
		pset(x+111+8,y+8+16,11)end
		
		pset(110+8,8+17,8)
		
		
	end
		circ(110+8,8+17,8,3)

end

function	print_message(the_string)
		line_lenght=26

		rectfill(screen_start_x+5+2,screen_start_y+5+2,screen_width-5+2,screen_height-15+2,1)
		rectfill(screen_start_x+5,screen_start_y+5,screen_width-5,screen_height-15,0)
		rect(screen_start_x+5,screen_start_y+5,screen_width-5,screen_height-15,6)
		
		for i=0,#the_string/line_lenght do
			the_line=sub(the_string,i*line_lenght,i*line_lenght+line_lenght-1)
			
			for j=0,#the_line do
				the_char = sub(the_line,j,j)
				print(the_char,screen_start_x+10+4*j,32+8*i,3)
				pause(1)
			end
		end
		
end


function	game_over()
	print_message("user connection lost-    rebooting backup memory   system on floor 1-         good luck              ")
	game_mode=k_title_mode
	_init()

end

function	check_victory()
	if(player.starbeast_dead and #enemy_list==0 and #sprite_list==0)then
		print_message("you have defeated the    star beast. victory!                                 ")
		game_mode=k_title_mode
	end
end

title_angle=0
function	draw_title()
	cls()
	clip()
	
	
	
	title_angle+=.01
	
	t_p1_x=cos(title_angle)*20
	t_p1_y=sin(title_angle)*20
	
	t_p2_x=cos(title_angle+.5)*20
	t_p2_y=sin(title_angle+.5)*20
	
	title_width=40
	
	for tx=0 ,title_width,.5 do
	
		sx = ((tx/title_width)*(t_p1_x-t_p2_x)-t_p1_x) 
		sh =  (tx/title_width)* (t_p1_y)/2 +40
		
	
		sspr(0+tx,96,1,24,sx*1.5+64,40-sh/2,1,sh*1.5)
	end
	

	print("clear floor of enemies and",10,90,7)
	print("find key to activate elevator",10,98,7)
	print("defeat star beast on level 3",10,106,7)
	print("hit -z- to start",10,120,7)
end

function _init()
	init_player()
	cls()
	
	if(k_use_sparse_map) then
		init_sparse_map()
	--make_room(3,3,15,10)
	
		new_floor()
	end
	
	--scan_map()
	
end

function _update()

	if(map_mode) then
		if(btn(0)) then map_x+=1 end
		if(btn(1)) then map_x-=1 end
		
		if(btn(2)) then map_y+=1 end
		if(btn(3)) then map_y-=1 end
	elseif (game_mode==k_title_mode)then
			if( btnp(4) )then game_mode=k_play_mode _init() pause(10) end
	elseif (game_mode==k_play_mode) then
	
	player.damage=false

	


	handle_buttons()
	update_actor(player)
	
	check_player()
	
	update_enemies()
	
	update_particle_list()
	update_shot_list()
	update_doors()
	
	check_victory()
	
	
	
	end
	
end

function _draw()
	--cls()
	
	if(map_mode) then
		sparse_draw()
	elseif (game_mode==k_title_mode) then
		palt(14,true)
		draw_title()
	elseif (game_mode==k_play_mode) then
	
	
		palt()
		rectfill(screen_start_x,screen_start_y,screen_width-1,64,5)
		rectfill(screen_start_x,65,screen_width-1,screen_height-1,15)
		rectfill(127,0,127,127,0)
		palt(0,false)
		palt(14,true)
		
		--
		--quick_cast_map_3d()
		clip(screen_start_x,screen_start_y,h_res,screen_height-screen_start_y)
		
		cast_view()
		
		start_clock=stat(1)
		draw_sprites()
		stop_clock=stat(1)
		--quick_draw_sprite(132,30.5,7.5,2,2)
		
		
		
		--draw_map()

		draw_gun()
		show_damage()
		clip()
		
		
		draw_hud()
		draw_radar()
		
		--print("fr: "..stat(1).." mem:"..stat(0),0,16,7)
		--print("spr: "..#sprite_list.." dor:"..#door_list.." enm:"..#enemy_list,0,24,7)
		--print(stat(1).." x: "..flr(player.x).." y: "..flr(player.y).." a: "..flr(player.direction*10)/10,0,0,7)
		--print(enemy_list[1].direction.." d "..delta_direction,30,30,7)
	end
	
	
	
end

__gfx__
0000000066666666dddddddd66666666ddddddddffffffff99999999ffffffff99999999cccccccc11111111cccccccc11111111eeee0eeee7766d1eeeeeeeee
00000000777777776666666677777777666666669999999944444444999999994444444477777777666666667777777766666666eeee0eeed77ddd11ee3bb3ee
0000000066666666dddddddd66666666ddddddddffffffff99999999ffffffff99999999cccccccc11111111cccccccc11111111eee666eed6666111ee3bb3ee
0000000066666666dddddddd66666666ddddddddffffffff99999999ffffffff99999999cccccccc11111111cccccccc11111111ee66666e17766d11ee3bb3ee
0000000066666666dddddddd66666666ddddddddffffffff99999999ffffffff99999999cccccccc11111111cccccccc11111111e6a777a6d7766d11ee3bb3ee
0000000066666666dddddddd66666666ddddddddffffffff99999999ffffffff99999999cccccccc11111111cccccccc11111111eeeeeeeed7766d11e3bb333e
0000000066666666dddddddd66666666ddddddddffffffff99999999ffffffff99999999cccccccc11111111cccccccc11111111eeeeeeeed7766d11e3bb333e
0000000066666666dddddddd66666666ddddddddffffffff99999999ffffffff99999999cccccccc11111111cccccccc11111111eeeeeeeed7766d11e111111e
3333333366666666dddddddd66666666ddddddddffffffff99999999ffffffff99999999cccccccc11111111cccccccc11111111eeeeeeeed7766d11eee94eee
3733337366666666dddddddd66666666ddddddddffffffff99999999f999999f94444449cccccccc11111111cccccccc11111111eeeeeeeed7766d11eee94eee
3333333366666666dddddddd66666666ddddddddffffffff99999999f955559f94555549cccccccc11111111cccccccc11111111eeeeeeeed7766d11eee94eee
3333333366666666dddddddd67777776d666666dffffffff99999999f966669f94666649cccccccc11111111c777777c16666661eeeeeeeed7766d11e444455e
3333333366666666dddddddd67505076d605056dffffffff99999999f955559f94555549cccccccc11111111c705057c16050561eeeeeeee17766d11e444455e
3333333366666666dddddddd67505076d605056dffffffff99999999f966669f94666649cccccccc11111111c705057c16050561eeeeeeeed6666111e222222e
37333373777777776666666677505077660505669999999944444444995555994455554477777777666666667705057766050566eeeeeeeed77ddd11ee4455ee
3333333366666666dddddddd67777776d666666dffffffff99999999f999999f9444444977777777666666667777777766666666eeeeeeeee7766d1eee4455ee
000000000000000000000000000000005555555555555555555555555555555566666666ddddddddeeeeeeee666666666666666666666666dddddddd00000000
00000000000000000000000000000000577777755777777557777775577777757777777766666666eeaeeaeedddddddddddddddd777777776666666600000000
000000000000000000000000000000005777777557777775577777755777777566666666ddddddddeaeaaeae111111111111111166666666dddddddd00000000
000000000000000000000000000000005777777557777775577777755777777561111116d111111daea99aea100000011000000165555556d555555d00000000
000000000000000000000000000000005777777557777775577777755777777561660016d166001dea98e9ae10bbbb0110bbbb0165666676d5dddd6d00000000
00000000000000000000000000000000566766655dd7ddd5566676655ddd7dd561600016d160001dae9e89ea100000011000000165666676d5dddd6d00000000
0000000000000000000000000000000055577765555777d5567775555d77755561000016d100001dea98e9ae10bbbb0110bbbb0165666676d5dddd6d00000000
00000000000000000000000000000000cc577765cc5777d5567775cc5d7775cc61000016d100001dae9e89ea100000011000000165666676d5dddd6d00000000
00000000000000000000000000000000cc577765cc5777d5567775cc5d7775cc61111116d111111dea98e9ae1dddddd11dddddd165666676d5dddd6d00000000
0000000000000000000000000000000055577765555777d5567775555d77755566666666ddddddddae9e89ea111111111111111165666676d5dddd6d00000000
0000000000000000000000000000000057777765577777d5567777755d77777566666666ddddddddea98e9ae66666666dddddddd65666676d5dddd6d00000000
00000000000000000000000000000000577766655777ddd5566677755ddd777566666666ddddddddae9e89ea66668886dddd888d65666676d5dddd6d00000000
000000000000000000000000000000005777777557777775577777755777777566666666ddddddddea98e9ae66662226dddd222d65777776d566666d00000000
000000000000000000000000000000005777777557777775577777755777777566666666ddddddddaea99aea66666666dddddddd66666666dddddddd00000000
00000000000000000000000000000000577777755777777557777775577777757777777766666666eaeaaeae7777777766666666777777776666666600000000
000000000000000000000000000000005555555555555555555555555555555566666666ddddddddeeaeeaee66666666dddddddd66666666dddddddd00000000
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeed66deeeed66deeeed66deeeed66deeeed66deeeddddddeeddddddeeddddddeeddddddeeddddddeeeeeeeee
ee5771eeee5771eeee5771eeee5771eeee5771eeed6776deed6776deed6776deed6776deed6776de1d6776d11d6776d11d6776d11d6776d11d6776d1eeeeeeee
e156751ee156751ee156751ee156751ee156751edd6006ddd00776dd0d6776dddd6776dddd6776dd1d6766d11d6766d11d6766d11d6766d11d6766d1eeeaaeee
e188881ee888751ee856751ee156751ee156751e1d0770d1077066d1006666551d6665511d6556d11d6766d11d6766d11d6766d11d6766d11d6766d1eea99aee
01800810e808700ee850051ee006751e015675101d0770d107706dd100d66d551dd665511dd55dd1e1d66d1ee1d66d1ee1d66d1ee1d66d1ee1d66d1eeea99aee
01888810e888700ee850051ee006751e015675101dd00dd1100dddd10dddddd11dddddd11dddddd1ee1111eeee1111eeee1111eeee1111eeee1111eeeeeaaeee
e156751ee156751ee156751ee156751ee156751ee11dd11ee11dd11ee11dd11ee11dd11ee11dd11eeee65eeeeee65eeeeee65eeeeee65eeeeee65eeeeeeeeeee
e156751ee156751ee156751ee156751ee156751eee1111eeee1111eeee1111eeee1111eeee1111eeeee65eeeeee65eeeeee65eeeeee65eeeeee65eeeeeeeeeee
e156751ee156751ee156751ee156751ee156751eeee16eeeeee16eeeeee16eeeeee16eeeeee16eeeeee77eeee7775eee77775eeee7765eeeeee77eeeeeeaaeee
e156751ee156751ee156751ee156751ee156751ee555555ee555555ee555555ee555555ee555555eee5995ee5966650e6666500e666500eeee5005eeeeeeeaee
e156751ee156751ee156751ee156751ee156751eeee16eeeeee16eeeeee16eeeeee16eeeeee16eeeee5995ee595555ee55555eee55555eeeee5555eeeaeeeeee
e156751ee156751ee156751ee156751ee156751eee5555eeee5555eeee5555eeee5555eeee5555eeeee11eeee1111eee1111eeeee111eeeeeee11eeeaeeeeeea
e156751ee156751ee156751ee156751ee156751eeee16eeeeee16eeeeee16eeeeee16eeeeee16eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeaeeeeeea
e156751ee156751ee156751ee156751ee156751eeee88eeeeee88eeeeee88eeeeee88eeeeee88eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeae
e156751ee156751ee156751ee156751ee156751eeee88eeeeee88eeeeee88eeeeee88eeeeee88eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeaeeeee
ee1111eeee1111eeee1111eeee1111eeee1111eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeaaeee
eeeeeeeeee7777eeeeeeeeeeee7777eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
e777777e7767dd77e777777e77d65577e777777ee777777e77776666e666666e66667777e777777eeeeeeeeeeeeeeeeeeeeeeee0e0eeeeeeeeeeeeeeeeeeeeee
e76666de6667ddd5e6dddd5eddd65556ed55556eee0880eee880dddeee0dddeeeddd000eee0000eeeeeeeeeeeeeeeeeeeeeeeee000eeeeeeeeeeeee0e0eeeeee
e70000de0007ddd5e6dddd5eddd65556ed55556eee0880eee880dddeee0dddeeeddd000eee0000eeeeeeeee0e0eeeeeeeeeeeee000eeeeeeeeeeeee000eeeeee
e70600de0007ddd5e6dddd5eddd65556ed55556e77666677e667777eee7777eee777777e77777777eeeeeee000eeeeeeeeeeee07110eeeeeeeeeeee000eeeeee
e70000de0007ddd5e6dddd5eddd65556ed55556e15600651e00651deeed51deee15d666e16666661eeeeeee000eeeeeeeeeeee07110eeeeeeeeeee07110eeeee
e70000de0007ddd5e6dddd5eddd65556ed55556e15600651e00651deeed51deee15d666e16666661eeeeee07110eeeeeeeeeee07110eeeeeeeeeee07110eeeee
e70000de0007ddd5e6dddd5eddd65556ed55556e15600651e00651deeed51deee15d666e16666661eeeee0000000eeeeeeeee0071100eeeeeeeee0071100eeee
e75555de5557ddd5e6dddd5eddd65556ed55556e15600651e00651deeed51deee15d666e16666661eee00707cd0700eeeee00707110700eeeee00700000700ee
e76666de6667ddd5e6dddd5eddd65556ed55556e77600677e00777deee7777eee77d666e76666667ee080c07cd0c080eee080c00000c080eee080c07cd0c080e
e76666de6667ddd5e6dddd5eddd65556ed55556e77666677e667d7deee7dd7eee77d666e76666667ee08010ccd01080eee08010ccd01080eee08010ccd01080e
e76666de6667ddd5e6dddd5eddd65dd6ed5dd56ee666666ee666dddeeeddddeeeedd666ee666666eeee0000cc10000eeeee0000ccd0000eeeee0000cc10000ee
e76666de6667ddd5e6dddd5eddd65116ed51156e00066000e660000eee0000eee000066e00066000eeeee00c1100eeeeeeeee00cc100eeeeeeeee00c1100eeee
e76666de6667ddd5e6dddd5eddd65556ed55556e555dd55505055110e011110e01155060555dd555eeeee0c000d0eeeeeeeee00c1100eeeeeeeee0c000d0eeee
e111111e1167dd11e111111e11d65511e111111e0001100000000110e011110e0110000000011000eeeee0cdddd0eeeeeeeee0c000d0eeeeeeeee0cdddd0eeee
eeeeeeeeee1111eeeeeeeeeeee1111eeeeeeeeee000ee000e000000eee0000eee000000e000ee000eeee0ccccddd0eeeeeee0ccccddd0eeeeeee0ccccddd0eee
eeeeeeeeeeeeeeee00000000000000000000000000000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee77777777eeeeeeeee5555eee000000000000000000000000
eeeeeeeeeeeeeeee00000000000000000080000000000000eeeeeeeeeeeeeeeeeeeeeeeeeeeaaaee66666666eeeeeeee66995eee000000000000000000000000
eeeeeeeeeeeeeeee00000000000000000800800000000000eee11eeeeeeeeeeeeee88eeeee9999aeeeeddeee999999995599555e000000000000000000000000
eeeeeeeeeeeeeeee00000000000000000080880000000000ee1006eeeeee8eeeeee88eeee499999aeee6deee667777666699995e000000000000000000000000
eeeeeeeeeeeaaeee00000000000000000800800000000000ee1007eeeee898eee888888ee494aa9aeee6deee666666665599995e000000000000000000000000
eeeeeeeeeeeeeaee00000000000000000000800000000000eee67eeeeeee8eeee228822ee494449aeee6deee6666666666aaaa5e000000000000000000000000
eeeaaeeeeaeeeeee00000000000000000000000000000000eeeeeeeeeeeeeeeeeee88eeeee49999eeee6deee55555555e5aaaa5e000000000000000000000000
eea99aeeaeeeeeea00000000000000000000000000000000eeeeeeeeeeeeeeeeeee22eeeeee444eee666555e55eeee55e555555e000000000000000000000000
eea99aeeaeeeeeea0000000000000000e5777eeeee577eeee5777eeee5777eeeeee577ee577777eee5777eee577777eee5777eeee5777eeeee57eeee00000000
eeeaaeeeeeeeeeae0000000000000000577e57eee5777eee577577ee57e577eeee5777ee577eeeee577e57eeeee577ee577e57ee577e57eee57777ee00000000
eeeeeeeeeeaeeeee0000000000000000577e57eeee577eeeeee577eeeee577eee57757ee577eeeee577eeeeeee577eee577e57ee577e57ee577eeeee00000000
eeeeeeeeeeeaaeee0000000000000000577e57eeee577eeeee577eeeee577eee577e57ee57777eee57777eeeee577eeee5777eeee57777eee5777eee00000000
eeeeeeeeeeeeeeee0000000000000000577e57eeee577eeee577eeeeeee577ee577777eeeee577ee577e57eee577eeee577e57eeeeee57eeeee577ee00000000
eeeeeeeeeeeeeeee0000000000000000577e57eeee577eee577eeeee57e577eeeee577eeeee577ee577e57eee577eeee577e57eeeeee57ee57777eee00000000
eeeeeeeeeeeeeeee0000000000000000e5777eeee57777ee577777eee5777eeeeee577ee57777eeee5777eeee577eeeee5777eeee5777eeeee57eeee00000000
eeeeeeeeeeeeeeee0000000000000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee00000000
eeeeee555555555555eeeeeeeeeeeeeeeeeeeeeeeeeeeeee66666666111111114444444444444444eeeeeeeeeeeeeeee65555556565555556555555655555565
eeee5566666666666655eeeeeeeeee777777777777eeeeee77777777666666664ffffff442222224eeeeeeeeeeeeeeee65555556565555556555555655555565
eee566666666666666665eeeeeeee77777777777777eeeee777777776666666645555554455c2554eeeeeeeeeeeeeeee65777756567775556555555655555565
ee56666666666666666665eeeeee2288888888888877eeee777777776666666644444444425c2534eeeeeeeeeeeeeeee6cccccc656cccccc6cccccc6cccccc65
e5666666666666666666665eeeee2288888888888877eeee779797776696996644444444425c2534ee7777eeeeeeeeee6cccccc656cccccc6cccccc6cccccc65
e5666666666666666666665eeeeee22222222222222eeeee779999776699966644444444425c2534e7666d7eeeeeeeee6dddddd6561111116111111611111165
566666666666666666666665eeeeee222222222222eeeeee77977977669699664444444446666664e766dd7eeeeeeeee66666666565555556666666655555565
566666666666666666666665eeeeeeeeeeeeeeeeeeeeeeee77977977666666664444444444444444e76ddd7eeeeeeeee61111116560000006000000600000065
566666666666666666666665eeeeeeeeeeeeeeeeeeeeeeee77777777669996664444444445dd5524556ddd55eeeeeeee60000006560000006000000600000065
566666666666666666666665eeeeeeeeeeeeeeeeeeeeeeee77997977669699664444444442dd9c24776ddd77e999999e60777706567770006000000600000065
566666666666666666666665eeeeee777777777777eeeeee77799977669669664444444442dd9c24e744447ee499444e6cccccc656cccccc6cccccc6cccccc65
566666666666666666666665eeeee56666666666667eeeee77997777669999664444444446666664e755557eee5555ee6cccccc656cccccc6cccccc6cccccc65
566666666666666666666665eeeee56666666666667eeeee77777777666666664444444444444444e777777eeee6deee6dddddd6561111116111111611111165
566666666666666666666665eeeeee555555555555eeeeee77777777666666664444444446555564eee6deeeeee6deee66666666565555556dddddd655555565
566666666666666666666665eeeeeeeeeeeeeeeeeeeeeeee77777777666666664444444444444444eee6deeeeee6deee66666666561111116666666611111165
555555555555555555555555eeeeeeeeeeeeeeeeeeeeeeee66666666111111114111111441111114e666555eee6655ee6ffffff656ffffff6ffffff6ffffff65
eeeeeeeeeed1c6eeeeeeeeeeeeeeeeeeeeeeeeeeeee0111111100eeeeeeeeeee0000000000000000000000000000000000000000000000000000000000000000
eeeeeeeeed1cc6eeeeeeeeeeeeeeeeeeeeeeeeeeee077144441770eeeeceecee0000000000000000000000000000000000000000000000000000000000000000
eeeeeeeed1cc6eeeeeeeeeeeeeeeeeeeeeeeeeeeee07c441144c70eeeeeeeeee0000000000000000000000000000000000000000000000000000000000000000
eeeeeeed1cc6eeeeeeeeeeeeeeeeeeeeeeeeeeeeee07c416614c70eeceec7eec0000000000000000000000000000000000000000000000000000000000000000
eeeeeed1ccc6eeeeeeeeeeeeeeeeeeeeeeeeeeeeeee0111551110eeeeeeeeeee0000000000000000000000000000000000000000000000000000000000000000
eeeeed1ccc6eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee1661eeeeeecee7ceec0000000000000000000000000000000000000000000000000000000000000000
eeeed1cccc6eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee11411411eeeeeeeeeeee0000000000000000000000000000000000000000000000000000000000000000
eeed1ccccccccc61ccc61c61cc6eeeeeeeeeeeeeeee1444444441eeeceec7eec0000000000000000000000000000000000000000000000000000000000000000
eeeeeeed1cccc6ed1c61c1c1c1c6eeeeeeeeeeeeeee144ffff441eeeeeeeeeee0000000000000000000000000000000000000000000000000000000000000000
eeeeeed1cccc6eed1c61ccc1cc6eeeeeeeeeeeeeee17749ff94771eecee7ceec0000000000000000000000000000000000000000000000000000000000000000
eeeeeed1ccc6eeed1c61c1c1c1c6eeeeeeeeeeeeee1a74999947a1eeeeeeeeee0000000000000000000000000000000000000000000000000000000000000000
eeeeed1ccc6eeeed1c61c1c1c1c6eeeeeeeeeeeeee115444444511eeceec7eec0000000000000000000000000000000000000000000000000000000000000000
eeeeed1cc6eeeeeeeeeeeeeeed1c6eeeeeeeeeeeeeee14444441eeeeeeeeeeee0000000000000000000000000000000000000000000000000000000000000000
eeeed1cc6eeeeeeeeeeeeeeeeed1c6eeeeeeeeeeeeee19944991eeeecee7ceec0000000000000000000000000000000000000000000000000000000000000000
eeeed1c6eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee19111191eeeeeeeeeeee0000000000000000000000000000000000000000000000000000000000000000
eeeeeeeeeee24666e24666e2466ee246624666eeeeee111ee111eeeeeeceecee0000000000000000000000000000000000000000000000000000000000000000
eeeeeeeeeee246246246ee246246246eee246eeeeeeeeeee00000000000000000000000000000000000000000000000000000000000000000000000000000000
eeeeeeeeeee246246246ee246246246eee246eeeeee88eee00000000000000000000000000000000000000000000000000000000000000000000000000000000
eeeeeeeeeee24646e2466624666624666e246eeeee8228ee00000000000000000000000000000000000000000000000000000000000000000000000000000000
eeeeeeeeeee246246246ee246246ee246e246eeee82aa28e00000000000000000000000000000000000000000000000000000000000000000000000000000000
eeeeeeeeeee246246246ee246246ee246e246eeee82aa28e00000000000000000000000000000000000000000000000000000000000000000000000000000000
eeeeeeeeeee24666e246662462462466ee246eeeee8228ee00000000000000000000000000000000000000000000000000000000000000000000000000000000
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee88eee00000000000000000000000000000000000000000000000000000000000000000000000000000000
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee00000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__gff__
0005000500050105010501050102060600000000000000000000000000060006000000002121111105000005050500000000000000060000000000000000000008080808080808080808080808080800060606060600000000000000000000000808080808080808080800000000000006060606060000000000000000000000
0000000000000000424246464200000000000000000000000000000000000000000000000000050005050600050505050000000000000000000042460000000000000000008800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
010101010101010101010101010101010101010101010000000000000101010100000000000000000000000909090909090b09090909090b090909000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010000000000011010101010101010101010101010010000000000000110100100000000000000000000000910101010101009101010101010100b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010000000000011010101010101010101010101010010000000000000110100100000000000000000000000b101010101010101010101010101009000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01000000012d2828282d0110101010101010101010030000000101030110100101010100000000000000000910101010101010101010101010100b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010000012d000000000003a8a8a8a810101010101001000000010f1010101010100f01000000000000000009101010101010091010101010101009000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010000012800000000002d101010101010c5101010a60000000310101010101010100100000000000000000910101010101009100d101010101009000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
030000012b000000000027101010101010101010100101010101101010101010101001010101010101010107101010100d10091010101010101009000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010000012b00000000002510101010101010101010271010101010101010101060101010271010101010271010101010100f0909090b091010090b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010000012800840000002d10101010101010101010251010101010101010101010101010251010101010251010101010100f091010101010101009000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010000012d00000000000310bb8abb1010101010100301010101101010101010101001010101010101010107101010100d1009100d101010101009000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01000001012d2828282d0110101010101010101010a600000001101010101010101001101010101010100109101010101010091010101010101009000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000001010101010110a8a8a8a8a810101010ac01000000010f1010101010100f01101010101010100109101010101010091010101010101009000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000000110101010101010101010101010ae010000000103010110100103010110100501011010010910101010101010101010101010100b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000000310101010101010101010101010100100000000000001101001101010101001101010100109101010101010101010101010101009000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01000000000001101010101010101010acaeacae100100000000000001262401101010101001101010100109101010101010091010101010101009000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010101010301010101010301010101010100000000000001101010101005010101101001010109090b090909090909090909090b0909000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2020202020202020202020202020202020202020202020202020200001101010101001000001101001070707070707070707070707070707070707000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2020202020000000000000000000000000000000000000000000200001010101010101000001262401000000000000000000000000000000000007000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
20202020000000000000000000000000000000000000000000002000000000000000000000011010010000000000000e00000e00000e0000000707000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2020200000000000000500000000000000000500000000000000200000000000000000000001101001000000000000000000000000000000000507000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2020000000000000000000000000000000000000000000000000200000000000000000000001101001000000000000000000000000000000000507000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2000000000000005000e00050000000005000e00050000000020200000000000000000000001101001000000000000000000000000000000000507000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2000000000000000000000000000000000000000000000000020010101010101010101010101101001000000000000000000000000000000000507000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2000000000000000000500000000000000000500000000000083010d10100d10100d10100d101010010000000000000e00000e00000e0000000707000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2000000000000000000000000000000000000000000000000081011010101010101010101010101001000000000000000000000000000000000007000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2000000000050000000000000000050000000000000000000020010101010101010101010101010101070700000007070707070707070707070707000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2000000000000000000000000000000000000000000000000020200020202020222020202020202020222000000020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
20000005000e00050000000005000e0005000000000000000000202000000000000020000000002000000000000022000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2020000000000000000000000000000000000000000000000000830000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2020200000050000000000000000050000000000000000000000000000000000000000000000000000000000002220000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2020202000000000000000000000000000000000000000000000200000000000000020000000002000000020202000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2020202020202020202020202020202020202020202020202020200020222020202020202020202220202020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
000100000a6201d6402766008650156401f630286302c6200a6200464008630076300463003640026300b60001600016000160001600016000260002600026000260001600016000160000000000000000000000
00030000080700b070120700f0700a070080700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00020000041700817011170161700f2700e2600b26009250072400524003230022300123001230012200000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00020000245702f5702b5701f57000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000800000762007620086400864008630076200761000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000300001507017070196701963000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00050000196301b6401e6402167024670266702a6702c6502b650286502664024630216301b620186101861000000000000000000000000000000000000000000000000000000000000000000000000000000000
000500001b120251402b1702c170271701d170141500e15014150221402b130261301e120151201d1202411000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344

