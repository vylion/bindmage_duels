pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
-- bindmage duels
-- by rucadi, dani, mnxanl, vylion

--11 saltar
--12 disparar
--13 matar o morir como lo veas
--14 escudo

current_scene = {}

title_scene = {}
function title_scene:init()
end
function title_scene:update()
	any_press = false
	for i=0,6 do
		if(btnp(i)) then
			any_press = true
			break
		end
	end
	if any_press then
		current_scene = game_scene
		current_scene:init()
	end
end
function title_scene:draw()
	cls()
	print("         bINDmAGE dUELS\n")
	print("kill the other team. yOU can \nmove, but you have to transfer \nyour powers (fire, shield) to \nyour pARTNER in order to win!")
	print("\n tEAM garnet  -> pLAYERS 1+2")
	print("\n tEAM emerald -> pLAYERS 3+4")
	print("\ncontrols (DEFAULT): \n    + -> move (yOU)\n   \142 -> fIRE   (pARTNER)\n   \151 -> sHIELD (pARTNER)\n")
	print("\n pRESS any KEY TO start")
end




garnet_scene = {}
function garnet_scene:init()
	music(0, 0, 12)
end
function garnet_scene:update()
	any_press = false
	for i=0,6 do
		if(btnp(i)) then
			any_press = true
			break
		end
	end
	if any_press then
		current_scene = game_scene
		current_scene:init()
	end
end
function garnet_scene:draw()
	cls()
	camera(0,0)
	print("    tEAM garnet hAS wON!!!\n\n")
	print("\n pRESS any KEY TO restart")

end


emerald_scene = {}
function emerald_scene:init()
	music(0, 0, 12)
end
function emerald_scene:update()
	any_press = false
	for i=0,6 do
		if(btnp(i)) then
			any_press = true
			break
		end
	end
	if any_press then
		current_scene = game_scene
		current_scene:init()
	end
end
function emerald_scene:draw()
	cls()
	camera(0,0)
	print("    tEAM emerald hAS wON!!!\n\n")
	print("\n pRESS any KEY TO restart")
end





game_scene = {}
function game_scene:init()
	p1 = new_player(0, 4, 4)
	p2 = new_player(1, 6, 4)
	p3 = new_player(2, 14, 16)
	p4 = new_player(3, 16, 16)

	-- random_torches()

	ally(p1, p2)
	ally(p3, p4)

	players = {p1, p2, p3, p4}
	music(1, 0, 12)

	clamp_x = getcameraxvalues()
	clamp_y = getcamerayvalues()
	ant_cam_x = mid(0, clamp_x, 400)+1
	ant_cam_y = mid(0, clamp_y, 400)+1
end

function game_scene:update()
	foreach(players, function(p)
		move_player(p)
		update_playerdust(p.dust, p.shield_cd <= 0, p.ammo)
		update_shield(p)
		update_cd(p)
		if not p.dead then
			player_shoot(p)
			player_shield(p)
		end

	end)

	update_shots()
	update_hit_effects()
	update_tomb_effects()
	update_magicdust()
	update_kill()
end

function game_scene:draw()
	cls()
	camera(0, 0) -- show ui elements w/o cam conditionals

	clamp_x = getcameraxvalues()
	clamp_y = getcamerayvalues()
	cam_x = mid(0, clamp_x, 400)+1
	cam_y = mid(0, clamp_y, 400)+1
	ant_cam_x = appr(ant_cam_x, cam_x, pixels_per_second/30)
	ant_cam_y = appr(ant_cam_y, cam_y, pixels_per_second/30)
	camera(ant_cam_x, ant_cam_y)

	--draw_torches()
	mapdraw(0, 0, 0, 0, 20, 20)

	--draw_lines(players[1], players[2], dark_green)
	--draw_lines(players[3], players[4], brown)

	mapdraw(0, 0, 0, 0, 20, 20, 2)
	

	lightning = rnd(100)
	if  lightning > 99 then
		rectfill(0, 0, 1024, 1024, 7)
		draw_rain_effects(1)
	else 
		draw_rain_effects(0)

		foreach(players, function(p)
			draw_player(p)
			draw_interface(p, ant_cam_x, ant_cam_y)
		end)
		draw_shots()
		draw_hit_effects()
		draw_tomb_effects()

		draw_magicdust()
	end
end

function new_player(num, x, y)
	local player = {}
	player.num = num
	player.x = x
	player.y = y
	player.dx = 0
	player.dy = 0
	player.accel = 0.05
	player.frame = 0
	player.f0 = 0
	player.standing = false
	player.d = 1
	player.ammo = 3
	player.ammo_cd = 0
	player.shield_cd = 0
	player.hp = 10
	player.dead = false
	player.shieldtime = 0
	player.stun = 0
	player.dust = {}
	make_playerdust(player, true)
	for i=0,player.ammo do
		make_playerdust(player,false)
	end
	return player
end

k_left=0
k_right=1
k_up=2
k_down=3
k_a=4
k_b=5

-- color palette
black = 0
dark_blue = 1
dark_pink = 2
dark_green = 3
brown = 4
dark_grey = 5
grey = 6
white = 7
red = 8
orange = 9
yellow = 10
green = 11
blue = 12
blue_grey = 13
pink = 14
light_pink = 15

hp_green=11
hp_red=8
hp_bar=5
y_bar=15

tombstone = 37

val = 0
flag = 0
grav = 0.28
t_step = 0.15
vxmax = 3
maxfall = 4
jumpforce = 4

shots = {}
torches = {}
torch_frame = 0

pixels_per_second = 20
magic_delay = 30

-- effects-----

hiteffects = {}
tombeffects = {}
magicdust = {}
rain_parts = {}

for i=0,48 do
	add(rain_parts,{
		x = rnd(128*2),
		y = rnd(128*2),
		s = 2 + flr(rnd(5)/4),
		spd = 2 + rnd(1),
		off = rnd(3),
		col = 7 --+ flr(0.5 + rnd(1))
	})
end


function draw_rain_effects(value)
	foreach(rain_parts, function(p)
		p.x += rnd(2) -- sin(p.off)
		p.y += p.spd*(rnd(4)+1)
		p.off += min(0.05, p.spd/8)

		if value == 1 then
			rectfill(p.x, p.y, p.x, p.y+(3*p.s), 0 )
		else
			rectfill(p.x, p.y, p.x, p.y+(3*p.s), p.col )
		end

		if p.y>128+4 then 
			p.x = rnd(256)
			p.y = -4
		end
		
	end)
end

function make_tomb_effect(startx, starty)

 local tomb_particle = {
   x=startx,
   y=starty,
   t = 0,

   life_time=20+rnd(10),


   size = 1,
   min_size = 0,
   max_size = 1+rnd(3),

   dy = rnd(0.7) * -1,
   dx = rnd(0.7) - 0.2,


   ddy = -0.05,

   col = 7
 }
 add(tombeffects,tomb_particle)
end

function update_tomb_effects()
  for p in all(tombeffects) do
    p.y += p.dy
    p.x += p.dx
    p.dy+= p.ddy

    p.t += 1/p.life_time
    p.size = max(p.min_size, p.max_size * (1-p.t) )
    if p.t > 0.7  then
      p.col = 6
    end
    if p.t > 0.9 then
      p.col = 5
    end

    if p.t > 1 then
      del(tombeffects,p)
    end
  end
end



function draw_tomb_effects()
  for p in all(tombeffects) do
    circfill(p.x, p.y, p.size, p.col)
  end
end

function make_hit_effect(startx, starty, colini, colfinal)

 local hit_particle = {
   x=startx,
   y=starty,
   t = 0,

   life_time=6+rnd(4),


   size = 1,
   max_size = 1+rnd(1),

   dx = rnd(4.0) -2.0;
   dy = rnd(4.0) -2.0;


   ddy = -0.1,

   col = colini,
   col2 = colfinal
 }
 add(hiteffects,hit_particle)
end


function update_hit_effects()
  for p in all(hiteffects) do
    p.y += p.dy
    p.x += p.dx
    p.dy+= p.ddy

    p.t += 1/p.life_time
    p.size = max(p.size, p.max_size * p.t )
    if p.t > 0.7  then
      p.col = p.col2
    end

    if p.t > 1 then
      del(hiteffects,p)
    end
  end
end



function draw_hit_effects()
  for p in all(hiteffects) do
    circfill(p.x, p.y, p.size, p.col)
  end
end

function make_magicdust(pl)

	local p = {
		x=pl.x,
		y=pl.y,
		target=pl.ally,

		life_time=magic_delay,

		size = 1,

		dx = 0,
		dy = 0,

		ddy = -0.05
	}

	p.col = (pl.num <= 1) and green or yellow
	p.col2 = (pl.num <= 1) and yellow or white

	add(magicdust,p)
end

function update_magicdust()
  for p in all(magicdust) do
  	p.dy+= p.ddy
    p.y += p.dy
    p.x += p.dx
	p.dy = (p.target.y - p.y)*8/p.life_time
	p.dx = (p.target.x - p.x)*8/p.life_time
    p.life_time -= 1

    if p.life_time <= 18 then
      del(magicdust,p)
    end
  end
end

function draw_magicdust()
  for p in all(magicdust) do
    circfill(p.x*8, (p.y - 0.5)*8, p.size, p.col)
      circfill(p.x*8, (p.y - 0.5)*8, p.size-1, p.col2)
  end
end

function make_playerdust(pl, is_shield)

	local p = {
		x=pl.x,
		y=pl.y,
		target=pl,

		size = 0,

		t = rnd(),
		dir = rnd() >= 0.5 and 1 or -1,
		t_rot = 45+rnd(91),
		r = 0.6 + rnd(0.2) - 0.1,
		ddy = rnd(0.5) - 0.25,
		ddx = rnd(0.5) - 0.25,

		active = true
	}

	if is_shield then
		p.col = blue
		p.col2 = white
		p.size += 1
	else
		p.col = (pl.num <= 1) and green or yellow
		--p.col2 = (pl.num <= 1) and yellow or white
	end

	add(pl.dust,p)
end

function update_playerdust(dust, shield, ammo)
	if(dust[1].active ~= shield) then
		if(dust[1].active ~= true) then
			dust[1].t = rnd()
			dust[1].dir = rnd() >= 0.5 and 1 or -1
			dust[1].t_rot = 45+rnd(91)
			dust[1].r = 0.6 + rnd(0.2) - 0.1
		end
		dust[1].active = shield
	end
	for i=2,5 do
		if(dust[i].active ~= (i <= ammo+1)) then
			if(dust[i].active ~= true) then
				dust[i].t = rnd()
				dust[i].dir = rnd() >= 0.5 and 1 or -1
				dust[i].t_rot = 45+rnd(91)
				dust[i].r = 0.6 + rnd(0.2) - 0.1
			end
			dust[i].active = (i <= ammo+1)
		end
	end

	for p in all(dust) do
		p.t += p.dir*1/p.t_rot
		p.x = p.r*cos(p.t) + p.target.x
		p.y = p.r*sin(p.t) + p.target.y

		if (p.t > 1) p.t = 0
		--p.dy+= p.ddy
		--p.dx+= p.ddx
	end
end

function draw_playerdust(dust)
	for p in all(dust) do
		if p.active then
			circfill(p.x*8, (p.y - 0.75)*8, p.size, p.col)
			if(p.size>0) circfill(p.x*8, (p.y - 0.75)*8, p.size-1, p.col2)
		end
	end
end

--------------------------------------------

function quickdel(t,i)
    local n=#t
    if (i>0 and i<=n) then
            t[i]=t[n]
            t[n]=nil
    end
end

function new_shot(pl)
	shot = {}
	shot.dx = pl.d*0.25
	shot.pl = pl
	if pl.num <= 1 then
		shot.sprite = 5
	else
		shot.sprite = 21
	end
	shot.flip_x = pl.d < 0
	shot.flip_y = false
	shot.friendly = {}
	shot.friendly[pl.ally.num] = true
	shot.friendly[pl.num] = true
	shot.damage = 1
	shot.level = 0
	shot.delay = magic_delay-18

	return add(shots,shot)
end


function solid_player(num, x, y)
	val=mget(x, y)
	flag = fget(val, 1)--0 = terrain flag
	coli = false
	foreach(players, function (p)
		if (p.num != num) then
			if not coli then
				coli = (y > p.y-1 and y < p.y) and (x < p.x+0.5 and x > p.x-0.5)
			end
		end
	end)
	return (flag or coli)
end

function solid(x, y)
	val=mget(x, y)
	flag = fget(val, 1)--0 = terrain flag
	return flag
end

function move_player(pl)
	accel = pl.accel
	if (not pl.standing) then
		accel = accel/2
	end

	--player control
	if (btn(k_left, pl.num)) then
		pl.dx = pl.dx - accel
		pl.d = -1
	end
	if (btn(k_right, pl.num)) then
		pl.dx = pl.dx + accel
		pl.d = 1
	end
	if (not pl.dead) then
		if (btn(k_up, pl.num) and pl.standing) then
			pl.dy = -0.5
			sfx(11)
		end

		--frame
		if (pl.standing) then
			pl.f0 = (pl.f0+abs(pl.dx)*2+4) % 4
		else
			pl.f0 = (pl.f0+abs(pl.dx)/2+4) % 4
		end

		if (abs(pl.dx) < 0.1) then
			pl.frame = 0
			pl.f0 = 0
		else
			pl.frame = 0 + flr(pl.f0)
		end

		-- x movement
		xaux = pl.x + pl.dx + sgn(pl.dx)*0.3
		if (not solid_player(pl.num, xaux, pl.y - 0.5)) then
			pl.x = pl.x + pl.dx
		else
			while (not solid_player(pl.num, pl.x + sgn(pl.dx)*0.3, pl.y-0.5)) do
				pl.x = pl.x + sgn(pl.dx)*0.1
			end
		end
	end
	pl.standing = false
	-- y movement
	if (pl.dy < 0) then
		if (solid_player(pl.num, pl.x-0.2, pl.y+pl.dy-1) or
			solid_player(pl.num, pl.x+0.2, pl.y+pl.dy-1)) then
			pl.dy = 0
			while ( not (
				solid_player(pl.num, pl.x-0.2, pl.y-1) or
				solid_player(pl.num, pl.x+0.2, pl.y-1)))
				do
				pl.y = pl.y - 0.01
			end
		else
			pl.y = pl.y + pl.dy
		end
	else
		if (solid_player(pl.num, pl.x-0.2, pl.y+pl.dy) or
			solid_player(pl.num, pl.x+0.2, pl.y+pl.dy)) then
			pl.standing=true
			pl.dy = 0

			while (not (
				solid_player(pl.num, pl.x-0.2,pl.y) or
				solid_player(pl.num, pl.x+0.2,pl.y)
				)) do
				pl.y = pl.y + 0.05
			end
		else
			pl.y = pl.y + pl.dy
		end
	end

	-- gravity
	pl.dy = pl.dy + 0.04

	-- x friction
	if (pl.standing) then
		pl.dx = pl.dx*0.8
	else
		pl.dx = pl.dx*0.9
	end
end

function update_shield(pl)
	if (pl.shieldtime > 0) then
		pl.shieldtime -= 1
	end
end

function update_cd(pl)
	if (pl.shield_cd > 0) then
		pl.shield_cd -= 1
	end
	if (pl.ammo_cd > 0) then
		pl.ammo_cd -= 1
		if(pl.ammo_cd == 0) pl.ammo = 3
	end
	if (pl.stun > 0) then
		pl.stun -= 1
	end
end

function player_shoot(pl)
	if(btnp(k_a, pl.num) and pl.ammo > 0) then
		pl.ammo -= 1;
		pl.ammo_cd = 45
		new_shot(pl.ally)
		--sfx(12)
		make_magicdust(pl)
	end
end

function player_shield(pl)
	if(btnp(k_b, pl.num) and pl.shield_cd <= 0) then
		pl.ally.shieldtime = 15
		pl.shield_cd = 120
		sfx(14)
	end
end

function collide_shoot(shot)
	ret = {}
	ret["coli"] = false
	ret["shield"] = false
	foreach(players, function (p)
		if (shot.friendly[p.num] == nil) then
			if not ret["coli"] then
				ret["coli"] = ((shot.y-0.2 > p.y-1 and shot.y-0.2 < p.y) or
						(shot.y+0.2 > p.y-1 and shot.y+0.2 < p.y)) and
						((shot.x < p.x+0.5 and shot.x > p.x-0.5))
				if ret["coli"] then
					if (not p.dead and p.shieldtime <= 0) then
						p.hp -= shot.damage
						--stun impulse
						p.dx += shot.dx
						p.dy -= 0.2
						--stun effect
						p.stun = 15
						if (p.hp <= 0) then
							p.dead = true
							-- tomb effect
							for i=0,rnd(30) do
								make_tomb_effect(p.x*8,p.y*8)
							end
							sfx(13)
						end
					elseif (p.shieldtime > 0) then
						ret["shield"] = true
						shot.dx = -shot.dx
						shot.flip_x = not shot.flip_x
						shot.friendly = {}
						shot.friendly[p.ally.num] = true
						shot.friendly[p.num] = true
						if (shot.level < 2) then
							shot.damage *= 1.5
							shot.level += 1
							shot.dx = shot.dx*1.5
						end
						for i=0,rnd(2)+4 do
							make_hit_effect(p.x*8,(p.y-0.5)*8,dark_blue,white)
						end
					end
					--hit efect
					if (shot.friendly[0] != nil) then
						for i=0,rnd(2)+4 do
							make_hit_effect(p.x*8,(p.y-0.5)*8,dark_blue,green)
						end
					else
						for i=0,rnd(2)+4 do
							make_hit_effect(p.x*8,(p.y-0.5)*8,red,yellow)
						end
					end
 					sfx(16)
				end
			end
		end
	end)
	return ret
end

s_delay = 0

function update_shots()
	local i = 1
	while shots[i] ~= nil do
		if shots[i].delay > 0 then
			shots[i].delay -= 1
			if(shots[i].delay == 0) then
				shots[i].x = shots[i].pl.x
				shots[i].y = shots[i].pl.y-0.5
				shots[i].pl = nil
				sfx(12)
			end
			i += 1
		else
			shots[i].x += shots[i].dx
			shots[i].flip_y = not shots[i].flip_y
			local sx = shots[i].x
			local sy = shots[i].y
			coll = collide_shoot(shots[i])
			if solid(sx, sy+0.2) or
				solid(sx, sy-0.2) then
				if (shot.friendly[0] != nil) then
					for i=0,rnd(2)+4 do
						make_hit_effect(sx*8,sy*8,dark_blue,green)
					end
				else
					for i=0,rnd(2)+4 do
						make_hit_effect(sx*8,sy*8,red,yellow)
					end
				end
 				sfx(15)
				quickdel(shots, i)
			elseif coll["coli"] and not coll["shield"] then
				quickdel(shots, i)
			else
				i += 1
			end
		end
	end
end

function ally(p1, p2)
	p1.ally = p2
	p2.ally = p1
end

function draw_player(pl)
	if (not pl.dead) then
		if (pl.stun > 0 and pl.stun % 2 == 0) then
			spr(16,pl.x*8-4,pl.y*8-8, 1, 1, pl.d < 0)
		else
			spr(16*pl.num+1 + pl.frame,pl.x*8-4,pl.y*8-8, 1, 1, pl.d < 0)
		end
		if (pl.shieldtime > 0) then
			circ(pl.x*8,pl.y*8-4, 5, blue)
			circ(pl.x*8,pl.y*8-4, 4.75, white)
		end
		draw_playerdust(pl.dust)
	else
		spr(tombstone+pl.num, pl.x*8-4,pl.y*8-8, 1, 1, pl.d < 0)
	end
end

function draw_shots()
	foreach(shots, function(s)
		if(s.delay <= 0) spr(s.sprite+s.level, s.x*8-4, s.y*8-4, 1, 1, s.flip_x, s.flip_y)
	end)
end

function draw_life(pl, pos_x, pos_y)
	rect(pos_x + pl.num*30 + 8, pos_y + y_bar*8 + 2, pos_x + (pl.num*30)+29, pos_y + y_bar*8 + 5, hp_bar)
	if (pl.hp > 0) then
		rectfill(pos_x + pl.num*30 + 9, pos_y + y_bar*8 + 3, pos_x + (pl.num*30 + 8) + pl.hp*2, pos_y + y_bar*8 + 4, hp_green)
	end
	if (pl.hp < 10) then
		rectfill(pos_x + (pl.num*30 + 9) + pl.hp*2, pos_y + y_bar*8 + 3, pos_x + (pl.num*30 + 8) + pl.hp*2 + (10-pl.hp)*2, pos_y + y_bar*8 + 4, hp_red)
	end
end

--function draw_life

function draw_icon(pl, pos_x, pos_y)
	if (not pl.dead) then
		spr(16*pl.num+1 + pl.frame,pos_x + pl.num*30 + 8, pos_y + y_bar*8 - 6, 1, 1, pl.d < 0)
	else
		spr(tombstone+pl.num, pos_x + pl.num*30 + 8, pos_y + y_bar*8 - 6, 1, 1, pl.d < 0)
	end
end

function draw_interface(pl, pos_x, pos_y)
	draw_life(pl, pos_x, pos_y)
	draw_icon(pl, pos_x, pos_y)
end

function getcameraxvalues()
	min_x = 128
	max_x = 0
	foreach(players, function(p)
		if (not p.dead) then
			if (p.x < min_x) min_x = p.x
			if (p.x > max_x) max_x = p.x
		end
	end)
	return (min_x + max_x)*8/2 - 64
end

function getcamerayvalues()
	min_y = 128
	max_y = 0
	foreach(players, function(p)
		if (not p.dead) then
			if(p.y < min_y) min_y = p.y
			if(p.y > max_y) max_y = p.y
		end
	end)
	return (min_y + max_y - 0.5)*8/2 - 64
end

function appr(val,target,amount)
	return val > target
 		and max(val - amount, target)
 		or min(val + amount, target)
end

function random_torches()
	for i=0,4+rnd(4) do
		t = {}
		t.x = rnd(18)
		t.y = rnd(17)
		add(torches, t)
	end
end

function draw_torches()
	torch_frame = (torch_frame + 1) % 8
	foreach(torches, function(t)
		mset(t.x,t.y,12 + flr(torch_frame/4))
	end)
end

function draw_lines(p1,p2,col)
	line(p1.x*8, (p1.y-0.5)*8, p2.x*8, (p2.y-0.5)*8, col)
end

function update_kill()
	if players[1].dead and players[2].dead then
		current_scene = emerald_scene
	else if players[3].dead and players[4].dead then
			current_scene = garnet_scene
		end
	end
	if (current_scene != game_scene) then 
		current_scene:init() 
	end
end


function _init()
	palt(15, true) -- beige color as transparency is true
    palt(0, false) -- black color as transparency is false

	current_scene = title_scene
	current_scene:init()
end

function _update()
	current_scene:update()
end

function _draw()
	current_scene:draw()
end

__gfx__
ffffffffffe22fffffe22fffffe22fffffe22fffffffffffffffffffffffffff00d0000d0d00000000d00000d66666670040000d0040000dffffffffffffffff
fffffffffe2222fffe2222fffe2222fffe2222ffffffffffffffffffffffffff066d6ddd166d6dd0166d6ddd5d6666760aa8a4dd0aa9894dffffffffffffffff
ff7ff7ffe200002fe200002fe200002fe200002ffffbbbbffff3333ffff1111fd6ddddddd6ddddd006dddddd55dddd66da89844d4a989894ffffffffffffffff
fff77ffffe0c0c2ffe0c0c2ffe0c0c2ffe0c0c2fdf3baaab6f13bbb3cfd133310dddddd10ddddd100dddddd155dddd66048a98420989a892ffffffffffffffff
fff77ffffe00002ffe000022fe000022fe00002ff3bbaaabf133bbb3fd11333100100010010001000000100055dddd66008aa820008aa820ffffffffffffffff
ff7ff7ffff200222ff200222ff200222ff200222fffbbbbffff3333ffff1111f6ddd066dd06d6dd0166ddd0655dddd66a45650a4a95650a4ffffffffffffffff
ffffffffffe222f2ffe2222fffe222ffffe222f2ffffffffffffffffffffffffdddd16ddd16ddd100ddddd16511111d6d4450a4dd4950a94ffffffffffffffff
fffffffffee222fffe2222ffffe2222fffe222ffffffffffffffffffffffffffddd10ddd10ddd10001ddd1011111111ddd4204dd4d42044dffffffffffffffff
ff777fffff422fffff422fffff422fffff422fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
f77777fff42222fff42222fff42222fff42222ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
7777777f4200002f4200002f4200002f4200002ffffaaaaffff9999ffff8888fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
f777777ff40b0b2ff40b0b2ff40b0b2ff40b0b2f8f9a777a2f89aaa95f289998ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
f777777ff400002ff4000022f4000022f400002ff9aa777af899aaa9f2889998ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ff777777ff200222ff200222ff200222ff200222fffaaaaffff9999ffff8888fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ff7777f7ff4222f2ff42222fff4222ffff4222f2ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
f77777fff44222fff42222ffff42222fff4222ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffc33fffffc33fffffc33fffffc33fffff5555ffff5555ffff5555ffff5555ffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
fffffffffc3333fffc3333fffc3333fffc3333fff552e55ff552455ff553c55ff553b55fffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffc300003fc300003fc300003fc300003f55622755556227555563375555633755ffffffffffffffffffffffffffffffffffffffffffffffffffffffff
fffffffffc08083ffc08083ffc08083ffc08083f5d6666755d6666755d6666755d666675ffffffffffffffffffffffffffffffffffffffffffffffffffffffff
fffffffffc00003ffc000033fc000033fc00003f566c6c65566b6b655668686556696965ffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffff300333ff300333ff300333ff3003335d6666655d6666655d6666655d666665ffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffc333f3ffc3333fffc333ffffc333f35d6ddd655d6ddd655d6ddd655d6ddd65ffffffffffffffffffffffffffffffffffffffffffffffffffffffff
fffffffffcc333fffc3333ffffc3333fffc333ff5d6666655d6666655d6666655d666665ffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffb33fffffb33fffffb33fffffb33fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
fffffffffb3333fffb3333fffb3333fffb3333ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffb300003fb300003fb300003fb300003fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
fffffffffb09093ffb09093ffb09093ffb09093fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
fffffffffb00003ffb000033fb000033fb00003fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffff300333ff300333ff300333ff300333ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffb333f3ffb3333fffb333ffffb333f3ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
fffffffffbb333fffb3333ffffb3333fffb333ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
0000000000000000000611110000000000000000000111116660000066666660000000000000000000000000000000110d000000000000000000000011111111
00000000000000000011111100111111000000000011111166660000166666660000000000000000000000000000011111160000000000000000000011111111
000000000000000011111111011111116000000011111111166660001666666660000000000000000000000000006111111100000000000000000000d111111d
000000000000000011111111011111111000000111111111161666001666666666600000000000610000000600001111111110000000000000000000d111111d
00000000000000001111111111111111160001111111111111666660166666666666660000001111000000d100011111111111600000000000000000dddddddd
00000000000000001111111111111111110011111111111111116660166666666666666000111111000001116111111111111111000000000000000ddddddddd
00000111600000001111111111111111111111111111111111116666116666666666666611111111000011111111111111111111111000000000000ddddddddd
000011111600000011111111111111111111111111111111111116661166666666666666111111110011111111111111111111111111000000000000dddddddd
0000000011111111111111666660000000000000000000000111111111666666666666666000000011110000111111100000111111111600000000001dd11111
0000000011111111111111666660000000000000000000000100000111666666666666666100001111111000111111110000111111111110000000001dd00111
0000000011111111111111166660000000000000000000000000001111166666666666666111061111110000111111100001111111111111600000001d000011
00000000111111111111111666660000000000000000000000000011111666666666666611111111111100001111111000111111111111111110000011000011
00000000111111111111111666660000000000000000000000000011111661111111111611111111111100001111111000111111111111111116000011000001
00000000611111111111111666666000000000001100000000000001111111111111111611111111111100001111111000111111111111111111000010000000
00000011011111111111111666666000600000001111000000000111111111111111111111111111100000001111101001111111111111111111000000000001
0000011100d111111111111166666600660000001111160000000111111111111111111111111111100000001111000011111111111111111111100000000001
11111110000611111111000000111111110000000001111100000111000000011111111111111111000111111111000011111110111000001111100000000000
11111110001111111111100000111111110100000011111100000111000000011111111111111111000001111100000011111110011100001111160000000000
11111110000016111111000000001111100000000011111100000111000000111111111111111111000000011100000011111100011110001111000000000000
1111111000000006111100000000111110000000000111110000111100000000110001111111111100000000110000001111100000111000111d001d00000000
11111000000000111111000000001011100000000001111100001111000000000000000111111111000000001100000011111000001111001100000100061111
11111000000001111111000000000001100000000001111100001111000000000000000001111111000000001100000011110000000011001110000100111111
1111100000000011100000000000000000000000000111110000001100000000000000000011111100000000000000001111000000000000116000000d111111
11110000000001111000000000000000000000000000111100000001000000000000000000011111000000000000000011100000000000001660000001011111
110000000000016d111111111111111111000000dddddddddd11111ddddddd11dddddddddddddddddddddddd1dd1111d111111111111111110100000000d1111
1100000000000100111111111111100111100000dddddddddd11111dddddd111dddddddddddddddddddddddd1d1111111111111111111111d00000000011111d
1d00000000000000111111111111100100000000dddddddddd111111ddddd111dddddddddddddddddddddddd11111111111111111111111160000000001111dd
1100000000000000111611111111110000100000ddddddddd1111111dddd1111dddddddddddddddd1ddddddd11111111dddddd11111111110000000000d11ddd
0000000000000001dd0011111111000000001100ddddddddd1111111dddd1111ddddddd1ddddddd11ddddddd11111111ddddddd111111100000000000011dddd
000000000000000d000011111111000000001000dddd1ddd111111111d111111ddddddd1ddddddd11ddd11dd11111111ddddddd1111111000000000001d11ddd
00000000000000000001d1111111110000000000dddd11dd1111111111111111dddddd11dddddd1111d111dd11111111dddddddd111111000000000000000ddd
1000000000000000001ddd111111000000000000ddd111dd1111111111111111dddddd11dddddd1111d1111d11111111dddddddd11111d000000000000001ddd
100000000000001100dddd11d1111111d11111ddd111111111111111111111110000000000000000000000000000000000000000000000000000000000000000
111000000000000000dddd11dd11111dd11111ddd1111111dd1dd111111111110000000000000000000000000000000000000000000000000000000000000000
00d00000000000010ddddd1ddd11111ddd111ddddd111111ddddddd1111111110000000000000000000000000000000000000000000000000000000000000000
0010000000000001010ddddddd1111dddd111ddddd11111ddddddddd111111110000000000000000000000000000000000000000000000000000000000000000
0000000000000011000ddddddddddddddddddddddd11111ddddddddd111111110000000000000000000000000000000000000000000000000000000000000000
0000000000000000001d1dddddddddddddddddddddd11ddddddddddd111111110000000000000000000000000000000000000000000000000000000000000000
000000000000000000100100dddddddddddddddddddddddddddddddd111111110000000000000000000000000000000000000000000000000000000000000000
000000000000000000100000d11111dddddddddddddddddddddddddd111111110000000000000000000000000000000000000000000000000000000000000000
00000ddd0000000000000010101001dd111111d111111111d1d11ddddddddddd0000000000000000000000000000000000000000000000000000000000000000
0000d11011000000d0000000000001dd111111dd11111d11d1111ddddddddddd0000000000000000000000000000000000000000000000000000000000000000
0001100010000000100000000000dddd11111ddd1111dddd111111dddddddddd0000000000000000000000000000000000000000000000000000000000000000
0000000010000000000000000001ddddd1111ddd1111dddd111111dddddddddd0000000000000000000000000000000000000000000000000000000000000000
000000010000000000000000001ddddddddddddd111ddddd111111dddddddddd0000000000000000000000000000000000000000000000000000000000000000
0000001d000000000000000001dddddddddddddd111ddddd1111111ddddddddd0000000000000000000000000000000000000000000000000000000000000000
0000000d000000001000000001dddddddddddddd1ddddddd111111dddddddddd0000000000000000000000000000000000000000000000000000000000000000
000000dd0000000010000000111d11dddddddddddddddddd1111111ddddddddd0000000000000000000000000000000000000000000000000000000000000000
dd11110011111dd1dddddddd000000ddddddddddddddddddddddddddaaaaaaaa0000000000000000000000000000000000000000000000000000000000000000
dd11000011111ddddddddddd00000dd11dddddddddddddddddddddddaaaaaaaa0000000000000000000000000000000000000000000000000000000000000000
ddd100001111ddddddddddd1000001d111ddddddddddddddddddddddaaaaaaaa0000000000000000000000000000000000000000000000000000000000000000
ddd60000d111dddddddddd000000011111ddddddddddddddddddddddaaaaaaaa0000000000000000000000000000000000000000000000000000000000000000
ddddd000d111ddddddddddd00000001111dd11ddddddd1ddddddd11daaaaaaaa0000000000000000000000000000000000000000000000000000000000000000
dd11d000d11ddddddddddddd00011d11111111ddddddd11dddddd111aaaaaaaa0000000000000000000000000000000000000000000000000000000000000000
d1001dd0dd11dddddddddddd000dd1111111111ddddd1111dddd1111aaaaaaaa0000000000000000000000000000000000000000000000000000000000000000
100010d1dddd11dd11dddddd0011d111111111111ddd11111ddd1111aaaaaaaa0000000000000000000000000000000000000000000000000000000000000000
11ddddd111100000dddddddd0110110111111111ddd1111100000000000000000000000000000000000000000000000000000000000000000000000000000000
111dddd111000000ddddddd111001001111111111dd1111100000000000000000000000000000000000000000000000000000000000000000000000000000000
11111dd111000000ddddddd111000011111111111dd1111100000000000000000000000000000000000000000000000000000000000000000000000000000000
1100100111000000ddddddd100000011111111111111111100000000000000000000000000000000000000000000000000000000000000000000000000000000
1100000011111000dddddd1100000111111111111111111100000000000000000000000000000000000000000000000000000000000000000000000000000000
1100000011111000dddddd1100001100001111111111111100000000000000000000000000000000000000000000000000000000000000000000000000000000
1100000011111000ddddd11100001000001111111111111100000000000000000000000000000000000000000000000000000000000000000000000000000000
1100000011110000dd11111100010000001111111111111100000000000000000000000000000000000000000000000000000000000000000000000000000000
__label__
066d6ddd066d6ddd066d6ddd066d6ddd066d6ddd066d6ddd066d6ddd066d6ddd066d6ddd066d6ddd066d6ddd066d6ddd066d6ddd066d6ddd066d6ddd066d6ddd
d6ddddddd6ddddddd6ddddddd6ddddddd6ddddddd6ddddddd6ddddddd6ddddddd6ddddddd6ddddddd6ddddddd6ddddddd6ddddddd6ddddddd6ddddddd6dddddd
0dddddd10dddddd10dddddd10dddddd10dddddd10dddddd10dddddd10dddddd10dddddd10dddddd10dddddd10dddddd10dddddd10dddddd10dddddd10dddddd1
00100010001000100010001000100010001000100010001000100010001000100010001000100010001000100010001000100010001000100010001000100010
6ddd066d6ddd066d6ddd066d6ddd066d6ddd066d6ddd066d6ddd066d6ddd066d6ddd066d6ddd066d6ddd066d6ddd066d6ddd066d6ddd066d6ddd066d6ddd066d
dddd16dddddd16dddddd16dddddd16dddddd16dddddd16dddddd16dddddd16dddddd16dddddd16dddddd16dddddd16dddddd16dddddd16dddddd16dddddd16dd
ddd10dddddd10dddddd10dddddd10dddddd10dddddd10dddddd10dddddd10dddddd10dddddd10dddddd10dddddd10dddddd10dddddd10dddddd10dddddd10ddd
0d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
166d6dd0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
d6ddddd0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0ddddd10000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
d06d6dd0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
d16ddd10000000000000000000000000000000000000000000000111600000000000000000000000000000000000000000000000000000000000000000000000
10ddd100000000000000000000000000000000000000000000001111160000000000000000000000000000000000000000000000000000000000000000000000
0d000000000000000000000000000000000000000000000000011111666000000000000000000000000000000000000000000000000000000000000000000000
166d6dd0000000000000000000000000000000000000000000111111666600000000000000000000000000000000000000000000000000000000000000000000
d6ddddd0000000000000000000000000000000000000000011111111166660000000000000000000000000000000000000000000000000000000000000000000
0ddddd10000000000000000000000000000000000000006111111111161666000000000000000000000000000000000000000000000000000000000000000000
01000100000000000000000000000000000000000000111111111111116666600000000000000000000000000000000000000000000000000000000000000000
d06d6dd0000000000000000000000000000000000011111111111111111166600000000000000000000000000000000000000000000000000000000000000000
d16ddd1000000000000000000000000000c000001111111111111111111166666000000000000000000000000000000000000000000000000000000000000000
10ddd1000000000000000000000000000c7c00001111111111111111111116666600000000000000000000000000000000000000000000000000000000000000
0d00000000000000000000000000000000c04221111b111111111111111111666660000000000000000000000000000000000000000000000000000000000000
166d6dd0000000000000000000000000000422221111111111111111111111666660000000000000000000000000000000000000000000000000000000000000
d6ddddd0000000000000000000000000004200002111111111111111111111166660000000000000000000000000000000000000000000000000000000000000
0ddddd1000000000000000000000000000040b0b2111111111111111111111166666000000000000000000000000000000000000000000000000000000000000
01000100000000000000000000000000000400002111111111111111111111166666000000000000000000000000000000000000000000000000000000000000
d06d6dd0000000000000000000000000611120ca22b1111a11111111111111166666600000000000000000c00000000d11000000000000000000000000000000
d16ddd1000000000000000000000001111114c7c121111111111111111111116666660000000000000000c7c0000000d11110000000000000000000000000000
10ddd100000000000000000000000111111442c2111a111111111111111111116666660000000000000000c00000b00011111600000000000000000000000000
0d000000000000000000000000061111111111c3311111b331111111111111116666666000000000000000022e000000111111110d0000000000000000000000
166d6dd000111111000000000011111111111c3333111b33331111111111111116666666000000000000002222e0000011111111111600000000000000000000
d6ddddd00111111160000000111111111111c3000031b300003111111111111116666bbbb000000000000200002e000011111111111100000000000000000000
0ddddd1001111111100000011111111111111c0808311b0909311111111111111666baaab36d0000000002c0c0e0000611111111111110000000000000000000
0100010011111111160001111111111111111c00003acb0000311111111111111666baaabb3666000000020000e000d111111111111111600000000000000000
d06d6dd011111111110011111111111111111130033c7c30033a11111111111116666bbbb6666660000022200200011111111111111111110000000000000000
d16ddd10111111111111111111111111111111c33313c1b333131111111111111166666666666666000020bb2e00111111111111111111111110000000000000
10ddd10011111111111111111111111111111cc333111bb333111111111111111166666666666666000000222ee1111111111111111111111111000000000000
00d0000d00d0000d00d0000d00d0000d00d0000d00d0000d0d0000001111111111666666666666666000000000d0000000d0000d00d0000d00d0000d00d0000d
066d6ddd066d6ddd066d6ddd066d6ddd066d6ddd066d6ddd166d6dd011111111116666666666666661000011166d6ddd066d6ddd066d6ddd066d6ddd066d6ddd
d6ddddddd6ddddddd6ddddddd6ddddddd6ddddddd6ddddddd6ddddd01111111111166666666666666111061106ddddddd6ddddddd6ddddddd6ddddddd6dddddd
0dddddd10dddddd10dddddd10dddddd10dddddd10dddddd10ddddd10111111111116666666666666111111110dddddd10dddddd10dddddd10dddddd10dddddd1
00100010001000100010001000100010001000100010001001000100111111111116611111111116111111110000100000100010001000100010001000100010
6ddd066d6ddd066d6ddd066d6ddd066d6ddd066d6ddd066dd06d6dd011111111111111111111111611111111166ddd066ddd066d6ddd066d6ddd066d6ddd066d
dddd16dddddd16dddddd16dddddd16dddddd16dddddd16ddd16ddd10111111111111111111111111111111110ddddd16dddd16dddddd16dddddd16dddddd16dd
ddd10dddddd10dddddd10dddddd10dddddd10dddddd10ddd10ddd1001111111111111111111111111111111101ddd101ddd10dddddd10dddddd10dddddd10ddd
0d000000111111100006111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111000
166d6dd0111111100011111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111600
d6ddddd0111111100000161111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111110000
0ddddd101111111000000006111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111d001d
01000100111110000000001111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111000001
d06d6dd0111110000000011111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111100001
d16ddd10111110000000001111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111600000
10ddd100111100000000011111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111116600000
0d000000110000000000016d11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111110100000
166d6dd01100000000000100111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111d0000000
d6ddddd01d0000000000000011111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111160000000
0ddddd10110000000000000011161111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111100000000
010001000000000000000001dd001111111111111111111111111111111111111111111111111111111111111111111111111111111111111111110000000000
d06d6dd0000000000000000d00001111111111111111111111111111111111111111111111111111111111111111111111111111111111111111110000000000
d16ddd1000000000000000000001d111111111111111111111111111111111111111111111111111111111111111111111111111111111111111110000000000
10ddd1001000000000000000001ddd111111111111111111111111111111111111111111111111111111111111111111111111111111111111111d0000000000
0d000000100000000000000000dddd11d1111111d11111ddd111111100d0000000d0000d00d0000d0d00000011111111111111d111111dd1dd11110000000000
166d6dd0111000000000000000dddd11dd11111dd11111ddd1111111166d6ddd066d6ddd066d6ddd166d6dd011111d11111111dd11111ddddd11000000000000
d6ddddd000d00000000000000ddddd1ddd11111ddd111ddddd11111106ddddddd6ddddddd6ddddddd6ddddd01111dddd11111ddd1111ddddddd1000000000000
0ddddd100010000000000000010ddddddd1111dddd111ddddd11111d0dddddd10dddddd10dddddd10ddddd101111ddddd1111dddd111ddddddd6000000000000
010001000000000000000000000ddddddddddddddddddddddd11111d00001000001000100010001001000100111dddddddddddddd111ddddddddd00000000000
d06d6dd00000000000000000001d1dddddddddddddddddddddd11ddd166ddd066ddd066d6ddd066dd06d6dd0111dddddddddddddd11ddddddd11d00000000000
d16ddd10000000000000000000100100dddddddddddddddddddddddd0ddddd16dddd16dddddd16ddd16ddd101ddddddddddddddddd11ddddd1001dd000000000
10ddd100000000000000000000100000d11111dddddddddddddddddd01ddd101ddd10dddddd10ddd10ddd100dddddddddddddddddddd11dd100010d100000000
0d000000000000000000000000000000101001dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd0000001000000000
166d6dd0000000000000000000000000000001ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd000000000000000
d6ddddd00000000000000000000000000000ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd11000000000000000
0ddddd100000000000000000000000000001dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd000000000000000000
01000100000000000000000000000000001dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd00000000000000000
d06d6dd000000000000000000000000001dddddddddddddddddddddddddddddddddd1ddddddddddddddddddddddddddddddddddddddddddd0000000000000000
d16ddd1000000000000000000000000001dddddddddddddddddddddddddddddddddd11dddddddddddddddddddddddddddddddddddddddddd1000000000000000
10ddd100000000000000000000000000111d11ddddddddddddddddddddddddddddd111dddddddddddddddddddddddddddddddddd11dddddd1000000000000000
0d000000000000000000000000000000000000dd00d000000d000000dddddddddd11111ddddddddddddddddd00d000000d00000011ddddd10000000000000000
166d6dd000000000000000000000000000000dd1166d6ddd166d6dd0dddddddddd11111ddddddddddddddddd166d6ddd166d6dd0111dddd11100000000000000
d6ddddd0000000000000000000000000000001d106ddddddd6ddddd0dddddddddd111111dddddddddddddddd06ddddddd6ddddd011111dd11000000000000000
0ddddd10000000000000000000000000000001110dddddd10ddddd10ddddddddd11111111ddddddddddddddd0dddddd10ddddd10110010011000000000000000
01000100000000000000000000000000000000110000100001000100ddddd11dd11111111dddddddddddddd10000100001000100110000000000000000000000
d06d6dd000000000000000000000000000011d11166ddd06d06d6dd0ddddd111111111111ddd11ddddddddd1166ddd06d06d6dd0110000000000000000000000
d16ddd10000000000000000000000000000dd1110ddddd16d16ddd10dddd11111111111111d111dddddddd110ddddd16d16ddd10110000000000000000000000
10ddd1000000000000000000000000000011d11101ddd10110ddd1001ddd11111111111111d1111ddddddd1101ddd10110ddd100110000000000000000000000
00d0000d00d0000d0d000000000000000110110111111111ddd111111dd111111111111111111111dddddd111111111111111111111000000000000000d00000
066d6ddd066d6ddd166d6dd00000000011001001111111111dd111111dd001111111111111111111ddddd11111111111111111111100000000000000166d6ddd
d6ddddddd6ddddddd6ddddd00000000011000011111111111dd111111d0000111111111111111111ddddd1111111111111111111110000000000000006dddddd
0dddddd10dddddd10ddddd1000000000000000111111111111111111110000111111111111111111dddd1111111111111111111111000000000000000dddddd1
00100010001000100100010000000000000001111111111111111111110000011111111111111111dddd11111111111111111111111110000000000000001000
6ddd066d6ddd066dd06d6dd0000000000000110000111111111111111000000011111111111111111d11111111111111111111111111100000000000166ddd06
dddd16dddddd16ddd16ddd100000000000001000001111111111111100000001111111111111111111111111111111111111111111111000000000000ddddd16
ddd10dddddd10ddd10ddd10000000000000100000011111111111111000000011111111111111111111111111111111111111111111100000000000001ddd101
00d0000d00d0000d0d00000000000000000000000111111111111110000000000001111111111111111111111111111111111111110000000000000000d00000
066d6ddd066d6ddd166d6dd0000000000000000001000001111111110000000000111111111111111111111111111111111110011110000000000000166d6ddd
d6ddddddd6ddddddd6ddddd000000000000000000000001111111110000000000011111111111111111111111111111111111001000000000000000006dddddd
0dddddd10dddddd10ddddd100000000000000000000000111111111000000000000111111111111111111111111111111111110000100000000000000dddddd1
00100010001000100100010000000000000000000000001111111110000000000001111111111111111111111111111111110000000011000000000000001000
6ddd066d6ddd066dd06d6dd0000000000000000000000001111111100000000000011111111111111111111111111111111100000000100000000000166ddd06
dddd16dddddd16ddd16ddd100000000000000000000001111111101000000000000111111111111111111111111111111111110000000000000000000ddddd16
ddd10dddddd10ddd10ddd10000000000000000000000011111110000000000000000111111111111111111111111111111110000000000000000000001ddd101
0d0000000000000000d0000000d0000d0d000000000011111111000000000000000001111111111111111111111111101110000000d0000000d0000d0d000000
166d6dd000000000166d6ddd066d6ddd166d6dd00000111111111000000000000000011111111111111111111111111001110000166d6ddd066d6ddd166d6dd0
d6ddddd00000000006ddddddd6ddddddd6ddddd0000111111111000000000000000001111111111111111111111111000111100006ddddddd6ddddddd6ddddd0
0ddddd10000000000dddddd10dddddd10ddddd1000111111111100000000000000001111111111111111111111111000001110000dddddd10dddddd10ddddd10
01000100000000000000100000100010010001000011111111110000000000000000111111111111111111111111100000111100000010000010001001000100
d06d6dd000000000166ddd066ddd066dd06d6dd00011111111110000000000000000111111111111111111111111000000001100166ddd066ddd066dd06d6dd0
d16ddd10000000000ddddd16dddd16ddd16ddd1001111111100000000000000000000011111111111111111111110000000000000ddddd16dddd16ddd16ddd10
10ddd1000000000001ddd101ddd10ddd10ddd100111111111000000000000000000000011111111111111111111000000000000001ddd101ddd10ddd10ddd100
0d000000000000000000000000000000000000000011111111000000000000000000000111111111111111111111000000000000000000000000000000000000
166d6dd0000000000000000000000000000000000011111111010000000000000000000111111111111111111100000000000000000000000000000000000000
d6ddddd0000000000000000000000000000000000000111110000000000000000000001111111111111111111100000000000000000000000000000000000000
0ddddd1000022e00000000000000000000000000422011111000000000000000000000c33100011111111111110000000000b330000000000000000000000000
01000100002222e000000000000000000000000422221011100000000000000000000c33330000011111111111000000000b3333000000000000000000000000
d06d6dd00200002e0000000000000000000000420000200110000000000000000000c30000300000011111111100000000b30000300000000000000000000000
d16ddd1002c0c0e00000000000000000000000040b0b2000000000000000000000000c08083000000011111100000000000b0909300000000000000000000000
10ddd100020000e000000000000000000000000400002000000000000000000000000c00003000000001111100000000000b0000300000000000000000000000
0d000000222002000000000000000000000000002002220000d000000d000000000000300333000000d000000d00000000003003330000000000000000000000
166d6dd020222e0000000000000000000000000042220200166d6ddd166d6dd0000000c333030000166d6ddd166d6dd00000b333030000000000000000000000
d6ddddd000222ee00000000000000000000000044222000006ddddddd6ddddd000000cc33300000006ddddddd6ddddd0000bb333000000000000000000000000
0ddddd105555555555555555555555000000005555555555555555555555dd1000005555555555555555555555dddd1000555555555555555555555500000000
010001005bbbbbbbbbbbbbbbbbbbb5000000005bbbbbbbbbbbbbbbbbbbb5010000005bbbbbbbbbbbbbb8888885000100005bbbbbbbbbbbbbbbb8888500000000
d06d6dd05bbbbbbbbbbbbbbbbbbbb5000000005bbbbbbbbbbbbbbbbbbbb56dd000005bbbbbbbbbbbbbb88888856d6dd0005bbbbbbbbbbbbbbbb8888500000000
d16ddd105555555555555555555555000000005555555555555555555555dd10000055555555555555555555556ddd1000555555555555555555555500000000
10ddd100000000000000000000000000000000000000000001ddd10110ddd100000000000000000001ddd10110ddd10000000000000000000000000000000000
0d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000

__gff__
0000000000000000020202020202000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0808080808080808080808080808080808080a08000900b6b6b6b6b6b6b6b6b6b6b6b6b6b6b60a0000000900b6b6b6b6b6b6b6b6b6b6b6b6b60ab60a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0809b6b6b6b6b64041b6b6b6b6b6b6b6b6b60a080009b6b6b6b6b64041b6b6b6b6b6b6b6b6b60a00000009b6b6b6b6b64041b6b6b6b6b6b6b60ab60a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0809b6b6b6b749454654b6b6b6b6b6b6b6b60a080009b6b6b6b749454654b6b6b6b6b6b6b6b60a00000009b6b6b6b749454654b6b6b6b6b6b60ab60a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0809b6b6504b87875253b6b64e55b6b6b6b60a080009b6b6504b87875253b6b64e55b6b6b6b60a00000009b6b6504b87875253b6b64e55b6b60ab60a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0809434442878787874748b64a874c4db6b60a080009434442878787874748b64a874c4db6b60a00000009434442878787874748b64a874c4d0ab60a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0808080808080809875758590a080808080808080009875187878787875758598787875d5eb60a00000009875187878787875758598787875d0ab60a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
080960618787878787878787878787876e6f0a08000960618787878787878787878787876e6f0a0000000960610b0b0b0b0b0b0b0b0b0b87870a6f0a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0809707172878787878787878787877d7e7f0a080009707172878787878787878787877d7e7f0a000000097071728787870b0b87878787877d0a7f0a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
080980b6828384850a0808099594a1a0b6900a08000980b682838485864f787c9594a1a0b6900a0000000980b682838485864f787c9594a1a00a900a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0809b6b6b6939797977597979797a292b6810a080009b6b6b6939797977597979797a292b6810a000000090b0bb69397979775979797970b0b0a810a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0809b6b6b6a30a09a6767a790a09b091b6b60a080009b6b6b6a3a4a5a6767a7996b2b091b6b60a00000009b6b6b6a3a4a5a6767a7996b2b0910ab60a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
08080809b6b3b4b55f8787778787b1b60a0808080009b6b6b6b3b4b55f8787778787b1b6b6b60a00000009b6b6b6b3b40b0b0b0b778787b1b60ab60a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
08080809b6b6565bb6658787877374b60a0808080009b6b6b6b6565bb6658787877374b6b6b60a00000009b6b6b6b6565bb6658787877374b60ab60a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0809b60a08095c62b66687876c6d0a0809b60a080009b6b6b6b65c62b66687876c6db6b6b6b60a00000009b60b0b0b5c62b66687870b0b0bb60ab60a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0809b6b6b6b66364b66768696bb6b6b6b6b60a080009b6b6b6b66364b66768696bb6b6b6b6b60a00000009b6b6b6b66364b66768696bb6b6b60ab60a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0809b6b6b6b6b60a09b6b60a09b6b6b6b6b60a080009b6b6b6b6b6b6b6b6b66ab6b6b6b6b6b60a00000009b6b6b6b6b6b6b6b6b66ab6b6b6b60ab60a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0809000000000000b6b600000000000000000a080009000000000000b6b600000000000000000a000000090b0b0b0b0b0b0b0b0b0b0b0b0b0b0a000a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
080900000000000000b6b6000000000000000a080009000000000000000000000000000000000a00000009000000000000000000000000000000000a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0808080808080808080808080808080808080808000808080808080808080808080808080808080000000808080808080808080808080808080808080000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0808080808080808080808080808080808080808000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000b6b6b6b60000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
011400001504500045000450200514045000450004509005140450004500045020051304500045000450200511045000450004502005100450004500045020051404500045000450200514045000450004502005
011400000e1750017500175001050d17500175001750e1050d17500175001751c1000c1750017500175231000b17500175001750a1050a17500175001753a1000d17500175001752e1000d17500175001751e100
011400001a3550c7530c7533b9031a3550c7530c7532e9031a3550c7530c7533b9031a3550c7530c7532e9031a3550c7530c7533b9031a3550c7530c7532e9031a3550c7530c7533b9031a3550c7530c7532e903
011400000c050150500c050150500c050150500c0501505010050150501005015050110501505011050150500c050150500c050150500c050150500c050150501005015050100501505011050150501105015050
011400000075300753007030075328653007030075300753007530075300753007532865300753007531a70300753007530070300753286530070300753007530075300753007530075328653007530075300000
01140000101550015000150001500e1550015000150001500415505155051550515506155061550715507155101550015000150001500e1550015000150001500415505155051550515506155061550715507155
011400001c4550c4500c4500c4501a4550c4500c4500c45010455114551145511455124551245513455134551c4550c4500c4500c4501a4550c4500c4500c4501045511455114551145512455124551345513455
011400000b05007050070500a0500505005050040500405004055040550705507055070550905509055090550b05007050070500a0500505005050040500405004055040550705507055070550a0550a0550a055
011400002405524055240552405523055230552305523055230552305523055230552305523055230552305523055230552305523055230552305523055230552405524055240552405523055230552305523055
01140000210552105521055210551f0551f0551f0551f0551f0551f0551f0551f0551f0551f0551f0551f0551f0551f0551f0551f0551f0551f0551f0551f0551f0551f0551f0551f0551f0551f0551f0551f055
001000000e7500e7500e750127501575016750177501a7501c7501e7501d7501c7501a7501775016750187501a7501d75020750237502575026750287502a7502b7502d7502e7502f7502f7502f7502f7502f750
0001000017750177501875018750197501a7501b7501c7501c7501d7501e7501e7501f750207502075021750227502275023750257502675027750287502a7502a7502c7502e7502f75031750337503575036750
00010000316543a6503d6503d6503a6503165025650126500d6500b6500b6500a6500965008650086500765006650056500365003650026500165201652016520165201652016520165201652016520165201652
00020000383503a350303502b350283502635023350203501e3501c3501a350183501535013350113500f3500d3500c3500b35009350073500635004350033500235002350023500135001350013500135001350
0002000013e7516e7519e751be751de751fe7521e7523e7524e7523e7521e751fe751ce7519e7517e7514e7513e7511e750fe750ee750ce750be750ae7509e7509e750ae750be750ce750fe7510e7512e7515e75
000100000d450114501645011450134500e4501645014450124500f45016450124500d4500c4000c4000c4000c4000c4000c4000c4000c4000c4000c4000c4000c4000c4000c4000c4000c4000c4000c4000c400
000200001175013750177501c7501f75024750297502f750297501b750127500c7500975008750097500c7500d750087500475003750037500475006750077500875006750037500175001750017500175001750
__music__
04 0a414244
01 00010244
00 00010248
00 40060405
00 40060405
00 00010208
00 00010209
00 00010208
02 00010209

