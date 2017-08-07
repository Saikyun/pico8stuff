pico-8 cartridge // http://www.pico-8.com
version 8
__lua__


debug = false
debugmsg = ""

function log(text)
 debugmsg = debugmsg .. "\n" .. text
end



-- basic helper functions

function fold(init,arr,pred)
 local newval = init
 if #arr == 0 then
  return newval
 end
 
 for pos = 1,#arr do
  x = arr[pos]
  newval = pred(newval,x,pos)
 end
 return newval
end

function filter(arr,pred)
 return fold({},arr
 ,function(acc,curr,pos)
   if pred(curr,pos) then
    add(acc,curr)
   end
   return acc
  end)
end

function fmap(arr,pred)
 return fold({},arr
 ,function(acc,curr)
   add(acc,pred(curr))
   return acc
  end)
end

function find(arr,pred)
 for x in all(arr) do
  if pred(x) then
   return x
  end
 end
 return nil
end

function dir(val)
 if val != 0 then
  return val/abs(val)
 else
  return 1
 end
end

function sign(val)
 return val != 0 and val/abs(val) or 0
end








-- time time time

-- span is table of time-value pairs
function moment(span,time)
 return find(span
 ,function (tv)
   return time < tv.t
  end).v
end

function progress(span,timestart,timestop)
 foreach
 (filter(span
  ,function(x)
    return x.t > timestart
           and x.t <= timestop
   end)
 ,function(x)
   x.f(x.t-timestart)
  end)
end




-- animations are functions of time and time-sprite pairs
function loopanim(frames,time)
 local totaltime = frames[#frames].t
 return moment(frames, time % totaltime)
end















size={w=8,h=8}

frameno=0

projectiles={}


-- #galanim

mygal =
 {pos={x=0,y=0}
 ,onhit=function() print("ouch") end
 ,inventory=
 {{name="g. gun"
  ,desc=
   {"..."
   ,"damn you."}
  ,sprite=
   {spr=35
   ,rect={x=0,y=0,w=4,h=4}
   ,off={x=5,y=0}}}
  ,{name="contract"
   ,desc=
    {"without this,\nthey would never pay me."}
   ,sprite=
    {spr=51}}
 }
 ,ammo=3
 ,maxammo=6
 ,size=size
 ,vel={x=0,y=0}
 ,basevel={x=700,y=20}
 ,lastvel={x=0,y=0}
 ,collisions={}
 ,tookabreak=true
 ,timesincechange=0}

other =
 {pos={x=80,y=80}
 }

standanim=
{{t=22*5,v=2}
,{t=34*5,v=3}}

runanim=
{{t=0.2 ,v=4}
,{t=0.4,v=5}
,{t=0.6,v=6}
,{t=0.8,v=7}}

risinganim=
{{t=0.5,v=20}
,{t=1.0,v=21}}

fallinganim=
{{t=0.5,v=22}
,{t=1.0,v=23}}

noammoanim=
{{t=0.8,v=34}
,{t=3.9,v=40}}

shootinganim=
{{t=0.5,v=34}
,{t=0.8,v=36}
,{t=1.1,v=37}
,{t=1.4,v=38}
,{t=1.7,v=39}
,{t=3.9,v=40}}

emptygunanim=
{{t=0.5
 ,v={spr=35
    ,rect={x=0,y=0,w=4,h=4}
	,off={x=5,y=0}}}
,{t=0.6
 ,v={spr=35
    ,rect={x=0,y=0,w=4,h=4}
	,off={x=4,y=0}}}
,{t=0.8
 ,v={spr=35
    ,rect={x=0,y=0,w=4,h=4}
	,off={x=5,y=0}}}
,{t=3.9
 ,v=nil}}

gunanim=
{{t=0.5
 ,v={spr=35
    ,rect={x=0,y=0,w=4,h=4}
	,off={x=5,y=0}}}
,{t=0.8
 ,v={spr=35
    ,rect={x=0,y=0,w=4,h=4}
	,off={x=4,y=0}}}
,{t=1.1
 ,v={spr=35
    ,rect={x=4,y=0,w=4,h=4}
	,off={x=1,y=-2}}}
,{t=1.4
 ,v={spr=35
    ,rect={x=4,y=4,w=4,h=4}
	,off={x=-5,y=4}
	,flipw=true}}
,{t=1.7
 ,v={spr=35
    ,rect={x=4,y=4,w=4,h=4}
	,off={x=-5,y=4}
	,flipw=true}}
,{t=3.9,v=nil}}





-- #monsteranim

deadwishywashyanim=
{{t=1.0
 ,v=11}}

wishywashyanim=
{{t=0.5
 ,v=10}
,{t=1.0
 ,v=11}}

fiendanim=
{{t=1.0
 ,v={spr=32
    ,rect={x=0,y=0,w=16,h=16}
	,off={x=0,y=0}}}}
--{{t=1.0
-- ,v=50}}

doormonanim=
{{t=1.0
 ,v=12}}

opendoormonanim=
{{t=1.0
 ,v=13}}


function smallframe(frame,flipsprite)
 local s = frame.spr
 local r = frame.rect
 local o = frame.off
 local flipw = not (frame.flipw == true) == flipsprite

 sspr((s%16)*8+r.x
     ,flr(s/16)*8+r.y
	 ,r.w,r.h
     ,0
 	 ,0
 	 ,r.w*2,r.h*2
 	 ,flipw)
end


function smallanim(creature,sprites,dt)
 local frame = loopanim(sprites, dt)

 if frame == nil then return end
 
 local flipsprite = creature.vel.x < 0
  or (creature.vel.x == 0
      and creature.lastvel.x < 0)

 local s = frame.spr
 local r = frame.rect
 local o = frame.off
 local flipw = not (frame.flipw == true) == flipsprite

 sspr((s%16)*8+r.x
     ,flr(s/16)*8+r.y
	 ,r.w,r.h
     ,creature.pos.x+creature.size.w*0.5-r.w*0.5+(o.x*dir(creature.lastvel.x))
 	 ,creature.pos.y+o.y
 	 ,r.w,r.h
 	 ,flipw)
end


function defanim(creature,sprites,dt)
 local flipsprite = creature.vel.x < 0
  or (creature.vel.x == 0
      and creature.lastvel.x < 0)

 spr(loopanim(sprites, dt)
    ,creature.pos.x
	,creature.pos.y
	,1,1
	,flipsprite)
end

function monsteranim(m,lastt,dt)
 if m.kind == "wishywashy" then
  if m.hp > 0 then
   defanim(m, wishywashyanim, m.timesincechange)
  else
   defanim(m, deadwishywashyanim, m.timesincechange)
  end
 elseif m.kind == "friend...?" then
  smallanim(m, fiendanim, m.timesincechange)
 elseif m.kind == "doormon" then
  if m.hp > 0 then
   defanim(m, doormonanim, m.timesincechange)
  else
   defanim(m, opendoormonanim, m.timesincechange)
  end
 end
end

function galanim(mygal,lastt,dt)
 local anim = standanim
   
 if mygal.action == "shoot" then
  anim = shootinganim

  smallanim(mygal, gunanim, mygal.timesincechange)

 elseif mygal.action == "noammo" then
  anim = noammoanim

  smallanim(mygal, emptygunanim, mygal.timesincechange)

 elseif mygal.airstate == "grounded"
        and mygal.vel.x != 0 then
  anim = runanim
	 
 elseif mygal.airstate != "grounded"
        and mygal.vel.y != 0 then
  
  anim = risinganim

  if mygal.vel.y > 0 then
   anim = fallinganim
  end

  dt *= abs(mygal.vel.y*2)
 end
  
 defanim(mygal, anim, mygal.timesincechange)
end








-- scene - #enecs

local screensize = {w=16*8,h=14*8}

function playeractions(scene,lastt,dt)

 scene.main.lastaction = scene.main.action
 
 if scene.main.recovery == nil then
  mygal.vel.x = 0
 end
 
 if scene.conversation != nil then
  scene.main.action = "talking"
  if type(convocontent(scene.conversation)) == "table" then
   if btnp(0,0) then
    scene.conversation.choice -= 1
   end
   if btnp(1,0) then
    scene.conversation.choice += 1
   end

   scene.conversation.choice = min(#(convocontent(scene.conversation)),scene.conversation.choice)
   scene.conversation.choice = max(1,scene.conversation.choice)
  end
  
  if btnp(5,0) then
   progressconvo(scene)
  end
  return
 end

 if scene.showinventory then
  if btnp(0,0) then
   scene.main.inventory.selected -= 1
  end
  if btnp(1,0) then
   scene.main.inventory.selected += 1
  end
  
  scene.main.inventory.selected = min(#scene.main.inventory,scene.main.inventory.selected)
  scene.main.inventory.selected = max(1,scene.main.inventory.selected)

  if btnp(4,0) then
   convo(scene,scene.main.inventory[scene.main.inventory.selected].desc)
  end
  
  if btnp(5,0) then
   scene.showinventory = false
  end
  return
 end

 if scene.main.recovery != nil then
  return
 end

 scene.main.action = ""
 scene.main.lastairstate = scene.main.airstate
 
 if(btn(0,0)) then
  scene.main.vel.x = -scene.main.basevel.x*dt
 end

 if(btn(1,0)) then
  scene.main.vel.x =  scene.main.basevel.x*dt
 end

 if btn(2,0) then
  scene.main.action = "jump"
 end
 
 if btn(4,0) then
  scene.main.action = "shoot"
 end

end

function bind(v,minv,maxv)
 v = max(minv,v)
 v = min(maxv,v)
 return v
end

function demonbehaviour(d,scene,lastt,dt)
 if d.oncollide != nil then
  if collides(d.pos,scene.main.pos,d.size,scene.main.size) then
   d.oncollide(scene,scene.main,d,lastt,dt)
  end
 end
 
 if d.kind == "wishywashy" then
  if d.recovery != nil then
   return
  end

  if d.hp <= 0 then
   d.saying = nil
   d.vel.y -= 0.2
   d.vel.x *= 0.99
   if d.vel.y > 0
      and fget(mget(flr(d.pos.x/8),flr(d.pos.y/8)+1),0) then
    d.pos.y = flr(d.pos.y)
	d.vel.y = 0
	d.vel.x = 0
   end
   
   if fget(mget(flr(d.pos.x/8)+1,flr(d.pos.y/8)),0)
      or fget(mget(flr(d.pos.x/8)-1,flr(d.pos.y/8)),0) then
	d.vel.x = 0
   end
   return
  end
  
  local t = scene.main                 -- target

  d.vel.x = -d.pos.x + t.pos.x
  d.vel.y = -d.pos.y + t.pos.y
  
  if scene.main.action == "shoot"
     and canshoot(scene.main)
	 and dir(t.lastvel.x) != dir(d.vel.x) then
	 camera()

   local forcex = max(0.25, 65-abs(d.vel.x))
   local forcey = max(0.15, 60-abs(d.vel.y))
   d.vel.x = bind(-dir(d.vel.x) * forcex, -d.basevel.x*4, d.basevel.x*4)
   d.vel.y = bind(-forcey, -d.basevel.y*4, d.basevel.y*3)
  else
   d.vel.x = bind(d.vel.x, -d.basevel.x*1.5, d.basevel.x*1.5)
   d.vel.y = bind(d.vel.y, -d.basevel.y, d.basevel.y)
  end
 elseif d.kind == "doormon" then
 end
end

function scenebehaviour(scene,lastt,dt)
 for obj in all(scene.objs) do
  if obj.kind != nil then
   demonbehaviour(obj,scene,lastt,dt)
  end
 end
end

function progressobj(obj,scene,lastt,dt)
 obj.timesincechange += dt
 if obj.recovery != nil then
  obj.recovery -= dt

  if obj.recovery <= 0 then
   obj.recovery = nil
  end
 end
 
 if obj.action == "jump"
    and canjump(obj) then
  obj.vel.y = -obj.basevel.y*1.5
 end

 if obj.action == "shoot" then
  if canshoot(obj) then
   shoot(obj,lastt,dt)
  else
   obj.action = ""
  end
 end
 
 obj.vel.y += obj.basevel.y*0.2

 move(obj.pos,obj.vel,dt)
end

function notdead(o)
 return o.dead != true
end

function progressscene(scene,lastt,dt)
 if scene.showinventory or scene.convo != nil then
  return
 end
 
 for o in all(scene.objs) do
  progressobj(o,scene,lastt,dt)
 end

 foreach(filter(projectiles,notdead),
  function (p)
  
   for o in all(scene.objs) do
    if collides(p.pos,o.pos,p.size,o.size) then
     o.onhit(scene,o,p)
	 p.dead = true
    end
   end
   move(p.pos,p.vel,dt)
   if p.pos.x > scene.lastcam.x + screensize.w
      or p.pos.x + p.size.w < scene.lastcam.x then
	del(projectiles,p)
   end
  end)
end





function fixbounds(scene)
 local pos  = scene.main.pos
 local size = scene.main.size

 pos.x = max(pos.x,scene.pos.x)
 pos.y = max(pos.y,scene.pos.y)

 pos.x = min(pos.x,scene.size.w-size.w+scene.pos.x)
-- pos.y = min(pos.y,scene.size.h-size.h+scene.pos.y)
end






function canjump(gal)
 return gal.airstate == "grounded"
        or (gal.airstate == "rising"
        and gal.timesincechange < 1)
end

function canshoot(gal)
 return gal.airstate == "grounded"
        and gal.vel.x == 0
end

function updatelastvel(o)
 if o.vel.x != 0 then
  o.lastvel.x = o.vel.x
 end
	
 if o.vel.y != 0 then
  o.lastvel.y = o.vel.y
 end
end

function fixcollisions(scene,lastt,dt)
  if scene.main.vel.y < 0 then
   scene.main.airstate = "rising"
  elseif scene.main.vel.y > 0 then
   scene.main.airstate = "falling"
  end
 
 local s=surrounding_tiles(scene.main.pos,size)
 
 foreach(s
        ,function (v)
          if 0!=mget(v.x,v.y) and fget(mget(v.x,v.y),0) then
           if debug then color(9) end

           testandfixcol(scene.main
                        ,{x=v.x*size.w
                         ,y=v.y*size.h}
		                ,scene.main.size
             		    ,size)
          else
           if debug then color(10) end
          end
		  
          if debug then
		   rectfill(v.x*size.w,v.y*size.h
                   ,size.w*v.x+size.w-1
                   ,size.h*v.y+size.h-1)
		  end
         end)

 local kind = fold
  ("none"
  ,scene.main.collisions
  ,function(acc,curr)
    if debug then
     color(14)
     rectfill(curr.cr.left ,curr.cr.top
 	         ,curr.cr.right-1,curr.cr.bot)
	end

    if debug then
--     log(acc.." huh "..curr.kind)
	end
	
    if acc=="none"
       and (curr.kind=="cornery"
            or curr.kind=="cornerx") then
     return "corner"
    elseif curr.kind    !="cornerx"
           and curr.kind!="cornery"
           and       acc!="none"
           and curr.kind!=acc then
     return "many"
    elseif (curr.kind != "cornery"
        and curr.kind != "cornerx")
        or acc        == "none" then
     return curr.kind
    end
	
    return acc
   end)

 local allcoll = scene.main.collisions
 local used = {}
 
 local grouped = fold
  ({x={},y={}} -- e.g x={{st=2,en=2,{cr}}}
  ,allcoll
  ,function(acc,curr,pos)
    local startendx = {st=curr.cr.left,en=curr.cr.right}
	local startendy = {st=curr.cr.top ,en=curr.cr.bot}

    local existingx = find(acc.x
	                      ,function (t)
	                        return t.st == startendx.st
	                           and t.en == startendx.en
							end)
								
    local existingy = find(acc.y
	                      ,function (t)
						    return t.st == startendy.st
	                           and t.en == startendy.en
						   end)
						   
	if existingx != nil then
	 add(existingx.boxes,pos)
	else
	 startendx.boxes = {pos}
	 add(acc.x,startendx)
	end
	
	if existingy != nil then
	 add(existingy.boxes,pos)
	else
	 startendy.boxes = {pos}
	 add(acc.y,startendy)
	end

    return acc
   end)

 for x in all(grouped.x) do
  log("x: "..x.st.." "..x.en.." #box "..#x.boxes)
 end

 for y in all(grouped.y) do
  color(7)
  log("y: "..y.st.." "..y.en)
 end

 local xrects = fold
  ({}
  ,grouped.x
  ,function(acc,curr)
    if #curr.boxes == 1 then
	 return acc
	end
	
    local box= fold({left=curr.st,right=curr.en}
	           ,curr.boxes
			   ,function (acc,curr)
			     if acc.top == nil then
				  acc.top = allcoll[curr].cr.top
				 else
				  acc.top = min(acc.top,allcoll[curr].cr.top)
				 end

                 if acc.bot == nil then
				  acc.bot = allcoll[curr].cr.bot
				 else
				  acc.bot = max(acc.bot,allcoll[curr].cr.bot)
				 end
				 log("posx "..curr)
				 add(used,curr)
				 
				 return acc
			    end)
	add(acc,box)
	return acc
   end)

 local yrects = fold
  ({}
  ,grouped.y
  ,function(acc,curr)
    if #curr.boxes == 1 then
	 return acc
	end

    local selectedboxes = filter(curr.boxes
			          ,function(x)
					    return find(used,function(y) return y == x end) == nil
					   end)
	if #selectedboxes < 2 then
	 return acc
	end
	
    local box= fold({top=curr.st,bot=curr.en}
	           ,selectedboxes
			   ,function (acc,curr)
			     if acc.left == nil then
				  acc.left = allcoll[curr].cr.left
				 else
				  acc.left = min(acc.left,allcoll[curr].cr.left)
				 end

                 if acc.right == nil then
				  acc.right = allcoll[curr].cr.right
				 else
				  acc.right = max(acc.right,allcoll[curr].cr.right)
				 end
				 log("posy "..curr)
				 add(used,curr)
				 
				 return acc
			    end)
	
	if box == nil then
	 return acc
	end
	
	add(acc,box)
	return acc
   end)

 log("sizexrects "..#xrects)
 for x in all(xrects) do
  log("xrect: "..x.top.." "..x.bot)

  if debug then
   color(11)
   rectfill(x.left ,x.top
           ,x.right-1,x.bot)
  end  
 end

 for y in all(yrects) do
  log("yrect: "..y.left.." "..y.right)

  if debug then
   color(12)
   rectfill(y.left ,y.top
           ,y.right-1,y.bot)
   color(13)
  end
 end

 local toporbottom = function(acc,curr)
   local w = curr.right - curr.left
   local h = curr.bot - curr.top

   if w < h then
    if abs(acc.x) < abs(w) then
     acc.x = w
	 if curr.left > scene.main.pos.x then
	  acc.x = -acc.x
	 end
    end
   else
    if abs(acc.y) < abs(h) then
     acc.y = h
 	 if curr.top > scene.main.pos.y then
 	  acc.y = -acc.y
	 end
    end
   end
   
   return acc
  end

 local rest = fold
 ({x=0,y=0}
 ,filter(allcoll
        ,function(o,pos)
		  return find(used, function(x) return x == pos end) == nil
		 end)
 ,function(acc,curr) return toporbottom(acc,curr.cr) end)

 local amnt = rest
 
 amnt = fold
  (amnt
  ,xrects
  ,toporbottom)
   
 amnt = fold
  (amnt
  ,yrects
  ,toporbottom)


 if debug then
  log("kind "..kind)
  log("amnt x:"..amnt.x
        .." y:"..amnt.y)
 end
 
 scene.main.pos.x+=amnt.x
 scene.main.pos.y+=amnt.y
 
 if  amnt.y < 0
 and kind != "corner"
 and scene.main.vel.y > 0 then
  scene.main.vel.y = 0
  scene.main.airstate = "grounded"
 elseif amnt.y > 0
    and kind != "corner"
    and scene.main.vel.y < 0 then
  scene.main.vel.y = 0
  scene.main.airstate = "falling"
 end
 
 foreach(scene.objs
        ,updatelastvel)
 
 scene.main.collisions = {}
 
 if scene.main.lastairstate != scene.main.airstate then
  scene.main.timesincechange = 0
 end

 if scene.main.lastaction != scene.main.action then
  scene.main.timesincechange = 0
 end
end









function fixcamera(scene)
 local pos  = scene.main.pos
 local size = scene.main.size
 local x = flr(pos.x) - screensize.w / 2 + size.w / 2
 local y = flr(pos.y) - screensize.h / 2 + size.h / 2

 local newx = x*0.03+scene.lastcam.x*0.97
 local newy = y*0.03+scene.lastcam.y*0.97

 newx = max(newx,scene.pos.x)
 newy = max(newy,scene.pos.y)
 newx = min(newx,(scene.pos.x+scene.size.w-(screensize.w)))
 newy = min(newy,(scene.pos.y+scene.size.h-(screensize.h)))

 local newlastcam = {x=newx
       			          ,y=newy}

 camera(newlastcam.x,newlastcam.y)

 scene.lastcam = newlastcam
end



function handleconvo(scene,lastt,dt)
 if scene.conversation != nil then
  camera(0,-14*8+1)
  color(1)
  rectfill(0,0,16*8,16)
  color(0)
  rectfill(1,1,16*8-2,15)
  color(7)
  camera(-2,-14*8-2)
  if type(convocontent(scene.conversation)) == "table" then
   local pos = scene.conversation.choice
   local size = #convocontent(scene.conversation)
   local str = convocontent(scene.conversation)[scene.conversation.choice][1]
   if pos < size and size > 1 then
    str = str.." ‘"
   end
   
   if pos > 1 then
    str = "‹ "..str
   end
   
   print(str
        ,0,0)
  else
   print(convocontent(scene.conversation)
        ,0,0)
  end
 end
end







function animobj(o,lastt,dt)
 if o.saying != nil then
  print(o.saying.words,o.pos.x,o.pos.y - 9)
  o.saying.time -= dt
  if o.saying.time <= 0 then
   o.saying = nil
   print("wtf")
  end
 end

 if o.kind != nil then
  monsteranim(o,lastt,dt)
 else
  galanim(o,lastt,dt)
 end
end

function drawobjs(scene,lastt,dt)
 foreach(scene.objs
        ,function(o) animobj(o,lastt,dt) end)
end

function drawstatus(scene,lastt,dt)
 if debug then return end
 
 camera()
 color(1)
 rectfill(0,0,16*8,16)
 color(0)
 rectfill(1,1,16*8-2,15)
 color(7)
 camera(-2,-2)
 local ammostring = ""
 local left = scene.main.ammo

 while left > 0 do
  if left >= 4 then
   left -= 4
   ammostring = ammostring.."™"
  elseif left >= 3 then
   left -= 3
   ammostring = ammostring.."˜"
  elseif left >= 2 then
   left -= 2
   ammostring = ammostring.."•"
  else
   left -= 1
   ammostring = ammostring.."‰"
  end
 end
 
 print("ammo "..ammostring
      ,0,0)
end



function renderinventory(inventory)
 if inventory.sprite.rect != nil then
  smallframe(inventory.sprite)
 else
  spr(inventory.sprite.spr)
 end
end


function drawinventory(scene,lastt,dt)
 if not scene.showinventory then
  return
 end
 
 camera()
 color(1)
 rectfill(0,0,16*8,16*8)
 color(0)
 rectfill(1,1,16*8-2,16*8-2)
 color(1)
 rectfill(0,15*8-1,16*8,16*8)
 color(0)
 rectfill(1,15*8,16*8-2,16*8-2)

 for x = 1,#scene.main.inventory do
  if scene.main.inventory.selected == x then
   camera(-2+(x-1)*-10,-2)
   color(2)
   rectfill(-1,-1,8,8)
   camera(-2,-15*8-1)
   color(7)
   print(scene.main.inventory[x].name)
  end
  camera(-2+(x-1)*-10,-2)
  renderinventory(scene.main.inventory[x])
 end
end




function changescene(scene,resetpos,lastcam)
 if currscene != nil then
  del(currscene.objs, currscene.main)
 end
 
 currscene = scene
 currscene.main = mygal
 
 if lastcam then
  currscene.lastcam = lastcam
 end
 
 add(currscene.objs,currscene.main)

 if resetpos == true then
  currscene.main.pos.x = currscene.startpos.x
  currscene.main.pos.y = currscene.startpos.y
 end
end

function refillammo(o)
 o.ammo = o.maxammo
end

isthatall =
{"what do you want?"
,{{"i'm out of ammo"
  ,{"is that all?"
   ,"..."
   ,"then go"}}
 ,{"nothing"
  ,{"don't waste my time"}}}}

function convo(scene, text)
 scene.conversation = {text,1}
end

function convocontent(convo)
 return convo[1][convo[2]]
end

function progressconvo(scene)
 if type(convocontent(scene.conversation)) == "table" then
  scene.conversation[1] = convocontent(scene.conversation)[scene.conversation.choice][2]
  scene.conversation[2] = 1
 else
  scene.conversation[2] += 1
 end
 
 if type(convocontent(scene.conversation)) == "table" then
  scene.conversation.choice = 1
 end

 if #scene.conversation[1] < scene.conversation[2] then
  scene.conversation = nil
 end
end

function showinventory()
 activateinventory(currscene)
end

function activateinventory(scene)
 scene.showinventory = true
 mygal.inventory.selected = 1
end

startscene =
{name="start"
,conversation = nil
,showinventory = false
,text = ""
,size={w=16*8,h=14*8}
,pos ={x=0 ,y=0}
,lastcam={x=0,y=0}
,startpos={x=3*8,y=4*8}
,main=nil
,objs=
{{kind="friend...?"
 ,size={w=8,h=16}
 ,pos={x=2*8,y=3*8}
 ,vel={x=0,y=0}
 ,lastvel={x=0,y=0}
 ,basevel={x=0.0,y=0.0}
 ,timesincechange=0
 ,onhit=function(scene)
   convo(scene, {"fool"})
  end
 ,oncollide=function(scene,gothit,hitter)
   gothit.pos.x = hitter.pos.x+hitter.size.w
   testandfixcol(gothit,hitter.pos,gothit.size,hitter.size)
   refillammo(scene.main)
   convo(scene,isthatall)
  end}
,{kind="doormon"
 ,size={w=8,h=8}
 ,pos={x=15*8,y=13*8}
 ,vel={x=0,y=0}
 ,lastvel={x=0,y=0}
 ,basevel={x=0.0,y=0.0}
 ,timesincechange=0
 ,hp=1
 ,onhit=function(scene,doormon,attack)
   doormon.hp-=attack.dmg
  end
 ,oncollide=function(scene,gothit,hitter)
   if hitter.hp <= 0 then
    changescene(scenes[2],false,scene.lastcam)
	gothit.pos.x = hitter.pos.x + hitter.size.w
    testandfixcol(gothit,hitter.pos,gothit.size,hitter.size)
	scene.objs = filter(scene.objs, function(o) return o.kind != "friend...?" end)
   else
    testandfixcol(gothit,hitter.pos,gothit.size,hitter.size)
   end
  end}}
,triggers=
 {update=
  {playeractions
  ,scenebehaviour
  ,progressscene
  ,fixcollisions
  ,fixcamera}
 ,draw  =
  {drawobjs
  ,drawstatus
  ,drawinventory
  ,handleconvo}}}

scenes=
{startscene
,{name="firstencounter"
 ,size={w=52*8,h=40*8}
 ,pos ={x=15*8,y=0}
 ,startpos={x=18*8,y=13*8}
 ,lastcam={x=0,y=13*8-screensize.h*0.5}
 ,main=nil
 ,objs=
 {{kind="doormon"
 ,size={w=8,h=8}
 ,pos={x=15*8,y=13*8}
 ,vel={x=0,y=0}
 ,lastvel={x=0,y=0}
 ,basevel={x=0.0,y=0.0}
 ,timesincechange=0
 ,hp=0
 ,onhit=function(scene,doormon,attack) end
 ,oncollide=function(scene,gothit,hitter)
   changescene(scenes[1],false,scene.lastcam)
   gothit.pos.x = hitter.pos.x - gothit.size.w
   testandfixcol(gothit,hitter.pos,gothit.size,hitter.size)
  end}
 ,{kind="wishywashy"
  ,hp=5
  ,size={w=8,h=8}
  ,pos={x=28*8,y=11*8}
  ,vel={x=0,y=0}
  ,lastvel={x=0,y=0}
  ,basevel={x=10,y=10}
  ,allwords=
   {"hi!"
   ,"who are you?"
   ,"ouch!"
   ,"hahaha!"}
  ,currword = 1
  ,timesincechange=0
  ,onhit=function(scene,doormon,attack)
    doormon.hp -= attack.dmg
   end
  ,oncollide=function(scene,gothit,hitter,dt)
    if hitter.hp <= 0 then
	 add(gothit.inventory
	    ,{name="dead wishywashy"
		 ,desc=
		  {"this job makes me sick"
		  ,"..."
		  ,"now where is my friend...?"}
		 ,sprite={spr=11}})
     del(scene.objs,hitter)
	 return
	end

    hitter.saying = {words=hitter.allwords[hitter.currword],time=3}
	hitter.currword += 1
	if hitter.currword > #hitter.allwords then
	 hitter.currword = 1
	end
	
    gothit.vel.x  = dir(gothit.pos.x-hitter.pos.x)*25
    gothit.vel.y  = -50
    gothit.recovery = 0.75
    hitter.vel.x = -gothit.vel.x*0.5
    hitter.vel.y = -gothit.vel.y*0.5
    hitter.recovery = 0.5
    move(gothit.pos,gothit.vel,0.1)
  end}}
 ,triggers=
  {update=
   {playeractions
   ,scenebehaviour
   ,progressscene
   ,fixcollisions
   ,fixcamera}
  ,draw  =
   {drawobjs
   ,drawstatus
   ,drawinventory
   ,handleconvo}}
}}






currscene = nil
lasttime  = nil
lastdrawtime = nil




function _init()
 print "starting game"

 menuitem(1,"inventory"
         ,showinventory)

 lasttime = time()
 lastdrawtime = time()

 changescene(scenes[1],true)
end

function nilfunc()
end

function shootphases(gal)
 return
 {{t=0.5
  ,f=function(t)
	if gal.ammo <= 0 then
	 return
	end
	
    gal.ammo -= 1
    add(projectiles
     ,{pos={x=gal.pos.x+gal.size.w*0.5-15+dir(gal.lastvel.x)*16
	       ,y=gal.pos.y+1}
	  ,size={w=30,h=3}
	  ,dmg=100
      ,vel={x=dir(gal.lastvel.x)
       * 500,y=0}
      ,kind="bullet"
     })
   end}
 ,{t=0.5
  ,f=function(t)
    gal.recovery = 1.5
   end}
 ,{t=0.5
  ,f=function(t)
    gal.pos.x += dir(gal.lastvel.x) * -3
   end}
 ,{t=0.7
  ,f=function(t)
    gal.pos.x += dir(gal.lastvel.x) * -2
   end}
 ,{t=1.3
  ,f=function(t)
    gal.pos.x += dir(gal.lastvel.x) * -1.5
   end}}
end

function whiffphases(gal)
 return
 {{t=0.5
  ,f=function(t)
    gal.action = "noammo"
    gal.recovery = 1.5
   end}}
end

function shoot(gal,lastt,dt)
 if gal.ammo > 0 then
  progress
  (shootphases(gal)
  ,gal.timesincechange-dt
  ,gal.timesincechange)
 else
  progress
  (whiffphases(gal)
  ,gal.timesincechange-dt
  ,gal.timesincechange)
 end
end

function drawscene(scene,lastt,dt)
 for f in all(scene.triggers.draw) do
  f(scene,lastt,dt)
 end
end

function updatescene(scene,lastt,dt)
 for f in all(scene.triggers.update) do
  f(scene,lastt,dt)
 end
end

function _update60()

 cls()

 local currtime = time()

 updatescene(currscene,lasttime,currtime-lasttime)

 lasttime = currtime

end

function surrounding_tiles(p,size)
 local tl=
  {x=flr(p.x/size.h)
  ,y=flr(p.y/size.w)}
 
 return {tl
							 ,{x=tl.x+1,y=tl.y}
							 ,{x=tl.x  ,y=tl.y+1}
							 ,{x=tl.x+1,y=tl.y+1}
							 }
end

function move(p,vel,dt)
 p.x+=vel.x*dt
 p.y+=vel.y*dt
end

function collides(t1,t2,s1,s2)
 local cr=colrect(t1,t2,s1,s2)
 if (cr.w==0 or cr.h==0) then
  return false
 end
 return true
end

function testandfixcol(t1,t2,s1,s2)
 local cr=colrect(t1.pos,t2,s1,s2)

 camera()
 
 if debug then
  rectfill(cr.left, cr.top, cr.right, cr.bot)
 end
 
 if (cr.w==0 or cr.h==0) then
  if debug then log("nocol") end
  
 -- corner
 elseif (abs(cr.h-cr.w) < 0.1) then
  local coll = {kind="cornerx"
               ,amnt=0
			   ,cr=cr}
  if (cr.left==t1.pos.x) then
   coll.amnt=-cr.w
	 else
	  coll.amnt= cr.w
	 end
	 
  add(t1.collisions
     ,coll)
  
  coll2 = {kind="cornery"
         ,amnt=0
		 ,cr=cr}
		 
	 if (cr.top==t1.pos.y) then
	  coll2.amnt= cr.h
	 else
	  coll2.amnt=-cr.h
	 end

  add(t1.collisions
     ,coll2)


 -- side
 elseif (cr.w < cr.h) then
  if debug then
   --log("x"..cr.w.." "..cr.h)
  end
  
  if (cr.left==t1.pos.x) then
   add(t1.collisions
      ,{kind="x"
       ,amnt=cr.w
	   ,cr=cr})
  else
   add(t1.collisions
      ,{kind="x"
       ,amnt=-cr.w
	   ,cr=cr})
  end


 -- top or bottom
 elseif (cr.w > cr.h) then
  if debug then
   --log("y"..cr.w.." "..cr.h)
  end
  
  if (cr.top==t1.pos.y) then
   add(t1.collisions
      ,{kind="y"
       ,amnt=cr.h
	   ,cr=cr})
	 else
   add(t1.collisions
      ,{kind="y"
       ,amnt=-cr.h
	   ,cr=cr})
	 end
 end
end

function colrect(p1,p2,s1,s2)
 local left = 0
 local right= 0
 local top  = 0
 local bot  = 0

 if (p1.x+s1.w>=p2.x
 and p2.x+s2.w>=p1.x) then
  left = max(p1.x,p2.x)
  right= min(p1.x+s1.w,p2.x+s2.w)
 end
  
 if (p1.y+s1.h>=p2.y
 and p2.y+s2.h>=p1.y) then
  top = max(p1.y,p2.y)
  bot = min(p1.y+s1.h,p2.y+s2.h)
 end
  
 return
 {left =left
 ,right=right
 ,top  =top
 ,bot  =bot
 ,w    =right-left
 ,h    =bot-top
 }
end

function _draw()

 --cls()

 if not debug then map(0,0,0,0) end
 
 foreach(projectiles
        ,drawprojectile)

 local currdrawtime = time()
 drawscene(currscene,lastdrawtime,currdrawtime-lastdrawtime)
 lastdrawtime = currdrawtime

 if debug and debugmsg != "" then
  camera()
  print(debugmsg)
  debugmsg = ""
 end
end

function drawprojectile(p)
 color(10)
 rectfill(p.pos.x-3
         ,p.pos.y
         ,p.pos.x+p.size.w+3
         ,p.pos.y)
 rectfill(p.pos.x
         ,p.pos.y-1
         ,p.pos.x+p.size.w
         ,p.pos.y+1)
 if p.dead == true then
  del(projectiles, p)
 end
end

function drawthing(t,d)
 rectfill(t.x
         ,t.y
         ,t.x+d.w-1
         ,t.y+d.h-1)
end






__gfx__
000000000009000000008800000880008800088000008800000000000000088000000000000000005000050050000500050505050005050500111dd000111dd0
000000000009900000088f00000f8800088888f088888f0000008800888888f00000000000000000050055005500500055555555000055550dd11ddd0dd11ddd
000000006660990000822200000222800f2222000882220008888f0008822200000000000000000005553000035550000605050500000505dd1111dddd1111dd
000000066666099008222020002228200000202f00f02020888222000f20222f00000000000000000c3c33000c3c3300656505050000500511d11ddd11d11ddd
00000006661109900822202000222820000dd0d00000d00f0020202f000d200000000000000000003333930003339330666505050000500511d1d1d111d1d1d1
0000000066660999008fddf0000fddf050d00d05000d0d0000f0d00000d00d0000000000000000003399930003999930606505050005050511dd1dd111dd1dd1
0000000566609999000d0d00000d0d000d00000005d000d0000d00000d0000500000000000000000399930000399333066655555000555551d1d1dd01d1d1dd0
00000dd55560999900050550000505500000000000000050000550005000000000000000000000000333000000333300050505050005050501d1dd0001d1dd00
0000ddd5550d99d90000000000000000000080000000000000000000888000000000000000000000000000000000000000040000000000000000000000000000
0000ddddd5dddd990000000000000000000888000000800000008000088880000000000000000000000000000000000000040000000000000000000000000000
00005ddddddd9999000000000000000000882f000088880080888800088888000000000000000000000000000000000000040000000000000000000000000000
0000555ddddddd990000000000000000088222f008882f0088882f0000882f000000000000000000000000000000000000040000000000000000000000000000
0500555000599990000000000000000008822220888222f0088222f0000222d00000000000000000000000000000000000040000000000000000000000000000
5050050005599900000000000000000008802d008802ddd00002ddd00002ddd00000000000000000000000000000000000040000000000000000000000000000
500555005009900000000000000000000088dd0008805d0000005d0000000dd00000000000000000000000000000000000040000000000000000000000000000
50000500059900000000000000000000000850000088050000000500000000500000000000000000000000000000000000040000000000000000000000000000
000000000000000000088000000000600008800000088f0000080000000880000008800000000000000000000000000000000000000000000000000000000000
00000000000000000088f000666006000088f80000882800008f8888008f8800008f800000000000000000000000000000000000000000000000000000000000
07000000000000000888222f60006000008222f0002288800082222f0085222f0082220000000000000000000000000000000000000000000000000000000000
007000000000000088820000000006000022280000222f0000222880002d28880022282000000000000000000000000000000000000000000000000000000000
00070066660000008882000000000600022280000002200002002200020d20000022282000000000000000000000000000000000000000000000000000000000
000778560660000088dd00009a006060f0dd0000000d0d00f000ddd5f00dd00000f6ddf000000000000000000000000000000000000000000000000000000000
000078560060000008d0d00099aa00060d00d0000000d0d0000d000000000d0000d60d0000000000000000000000000000000000000000000000000000000000
0000885566600000005055009a000000050055000000505500055000000000500056055000000000000000000000000000000000000000000000000000000000
0000588556000000070006600077fff0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00005555500000000070660607ffff50000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000555550000000007866600f888f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000055550000000008556500fffff00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000055550000000000555500f888f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0005555550000000050055000fffff00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0055555555500000055055507f88ff00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
005555555500000000555550ffff5000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
55555555ddddddd56666666600007777777777777777777000000000000000000000000000000000000000000000000000000000000000000000000000000000
55555555555555556666666600077777777777777777777000000000000000000000000000000000000000000000000000000000000000000000000000000000
252525255ddddd556666666600077777777777777777770000000000000000000000000000000000000000000000000000000000000000000000000000000000
58585858555555556666666600777777777777777777770000000000000000000000000000000000000000000000000000000000000000000000000000000000
2525252555ddd5555555555500566555665566555665500000000000000000000000000000000000000000000000000000000000000000000000000000000000
85858585555555555555555505555555555555555555500000000000000000000000000000000000000000000000000000000000000000000000000000000000
525252525555d5555555555505555555555555555555000000000000000000000000000000000000000000000000000000000000000000000000000000000000
85858585555555550500005055555555555555555555000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000650005000650005000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000650005000650005000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000550005000550005000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000650005000650005000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000650005000650005000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000550005000550005000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000650005000650005000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000650005000650005000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000f0f0f0f0f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000f0f0f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000f0f0f0f00000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000f0f000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000f0f0f00000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000f00000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000f00000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000f00000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__label__
20000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
30000030333000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
30000300300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
33300300333000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
30300300003000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
33303000333000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
33300030333000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00300300300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00300300333000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00300300003000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00303000333000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
30000030300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
30000300300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
33300300333000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
30300300303000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
33303000333000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
33300030300000000000000000000000000000001111101000000000000000000000000000000000111110100000000000000000000000000000000000000000
00300300300000000000000000000000000000001101000000000000000000000000000000000000110100000000000000000000000000000000000000000000
00300300333000000000000000000000000000001111101000000000000000000000000000000000111110100000000000000000000000000000000000000000
00300300303000000000000000000000000000001101000000000000000000000000000000000000110100000000000000000000000000000000000000000000
00303000333000000000000000000000000000001111101000000000000000000000000000000000111110100000000000000000000000000000000000000000
00000000000000000000000000000000000000001101000000000000000000000000000000000000110100000000000000000000000000000000000000000000
aa000aa00aa00aa0a000000000000000000000001111101000000000000000000000000000000000111110100000000000000000000000000000000000000000
a0a0a0a0a000a0a0a000000000000000000000001101000000000000000000000000000000000000110100000000000000000000000000000000000000000000
a0a0a0a0555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
a0a0a0a0555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
a0a0aa00252525252525252525252525252525252525252525252525252525252525252525252525252525252525252525252525252525252525252525252525
00000000585858585858585858585858585858585858585858585858585858585858585858585858585858585858585858585858585858585858585858585858
a0a0aaa0252525252525252525252525252525252525252525252525252525252525252525252525252525252525252525252525252525252525252525252525
a0a00a00858585858585858585858585858585858585858585858585858585858585858585858585858585858585858585858585858585858585858585858585
aa000a00525252525252525252525252525252525252525252525252525252525252525252525252525252525252525252525252525252525252525252525252
a0a00a00858585858585858585858585858585858585858585858585858585858585858585858585858585858585858585858585858585858585858585858585
a0a0aaa0555555550000a0a0aa00a0a0aaa000000000000011111111aaaaaaaa0000000000000000000000000000000000000000000000000000000000000000
00000000555555550000000000000000000000000000000011111111aaaaaaaa0000000000000000000000000000000000000000000000000000000000000000
aaa0aaa0252525250000a0a00000aaa00000a0a00000aaa011111111aaaaaaaa0000000000000000000000000000000000000000000000000000000000000000
a0a0aaa0585858580000a0a00a00a0a00000a0a00a00a0a011111111aaaaaaaa0000000000000000000000000000000000000000000000000000000000000000
aaa0a0a02525252500000a000000a0a00000aaa00000a0a011111111aaaaaaaa0000000000000000000000000000000000000000000000000000000000000000
a0a0a0a0858585850000a0a00a00a0a0000000a00a00a0a011111111aaaaaaaa0000000000000000000000000000000000000000000000000000000000000000
a0a0a0a0525252520000a0a00000aaa00000aaa00000aaa011111111aaaaaaaa0000000000000000000000000000000000000000000000000000000000000000
00000000858585850000000000000000000000000000000011111111aaaaaaaa0000000000000000000000000000000000000000000000000000000000000000
000000005555555500000000000000000000000000000000aaaaaaaaaaaaaaaa0000000000000000000000000000000000000000000000000000000000000000
000000005555555500000000000000000000000000000000aaaaaaaaaaaaaaaa0000000000000000000000000000000000000000000000000000000000000000
000000002525252500000000000000000000000000000000aaaaaaaaaaaaaaaa0000000000000000000000000000000000000000000000000000000000000000
000000005858585800000000000000000000000000000000aaaaaaaaaaaaaaaa0000000000000000000000000000000000000000000000000000000000000000
000000002525252500000000000000000000000000000000aaaaaaaaaaaaaaaa0000000000000000000000000000000000000000000000000000000000000000
000000008585858500000000000000000000000000000000aaaaaaaaaaaaaaaa0000000000000000000000000000000000000000000000000000000000000000
000000005252525200000000000000000000000000000000aaaaaaaaaaaaaaaa0000000000000000000000000000000000000000000000000000000000000000
000000008585858500000000000000000000000000000000aaaaaaaaaaaaaaaa0000000000000000000000000000000000000000000000000000000000000000
00000000555555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000555555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000252525250000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000585858580000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000252525250000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000858585850000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000525252520000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000858585850000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000333333330000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000333333330000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000333333330000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000333333330000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000333333330000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000333333330000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000333333330000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000333333330000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000

__gff__
0000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0f000f0f0f0f0f0f0f0f0f0f0f0f0f0f00000000000000000000000000000f0f0f0f0f0f0f0f0f0f0f0f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0f00000000000000000000000000000f0f0f0f0f0f0f0000000f0f0f0f0f0f0f0f0f000000000000000f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0f00000000000000000000000000000f00000000000f0f0f0f0f0f0f0f0f0f0f0000000000000000000f0f0f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0f00000000000000000000000000000f0000000000000000000f0f0f0f0f000000000000000000000000000f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0f00000000000f00000000000000000f0000000000000000000f0f0f000000000000000000000f0f0000000f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0f0f0f0f0f0f0f0f0f0f0f0f0000000f00000000000f0f0f000000000000000f0f0000000f0f00000000000f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0f00000000000000000000000000000f00000f000000000f00000000000f0f00000f000f000000000000000f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0f0000000f0f0000000000000000000f0f0000000000000f0f0f0f0f0f000000000f000f000000000000000f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0f000f0f0f0f0f0f0f0f0f0f0f0f0f0f0000000000000000000000000f000000000f0f0f000000000f0f000f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0f00000000000000000000000000000f0f0f0f0f0f0f0000000000000f0000000000000000000f0f0f00000f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0f00000000000000000000000000000f0000000000000f0f0f0000000f00000000000000000f0f000000000f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0f0f0f0f0f0f0f0f0f0000000000000f0000000000000000000f00000f00000000000000000f0000000f0f0f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0f00000000000000000000000000000f0000000000000000000000000f00000f0f0f000000000000000f0f0f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0f0000000000000000000000000000000000000000000000000000000f00000f0f0f00000000000f0f0f0f0f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f00000f0f0f00000000000f0f0f0f0f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f000000000000000f000000000000000f0f0f000000000f0f0f0f0f0f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f000000000000000f000000000000000f0f0f0000000000000000000f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f000000000000000f0000000f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0000000f0000000f0000000f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000f0000000f0000000f0000000f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000f0000000f000000000000000f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000f0000000f000000000000000f00000000000000000f0f0f0f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000f0000000f0f0000000000000f000f0f0f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000f0000000f0f0000000000000f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000f0000000f0f0f00000000000f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000f0000000f0f0f0f0f0f0f0f0f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000f0000000f0000000f00000000000000000f0f0f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000f00000000000f0000000f000f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000f0f0f0f0f0f0f0f0f0f0f000f0f0f0f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000f0f0f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
000800002553025530035300353025530255300453004530195301953005530055301953019530055300553010530105300553005530105301053005530055301953019530065300653019530195300553006530
0010000018550165501c5501c550155501c5501b5501a5501a5501a5501a5501a5501a5501955017550175501655016550185501b5501c5500000000000000000000000000000000000000000000000000000000
010c00000c6100e610106100c6100e610106100c6100e610106100c6100e610106100c6100e610106100c6100e610106100c6100e610106100c6100e610106100c6100e610106100c6100e610106100c6100e610
01240000107030c703107030e703007030c723107030c723007030e7030070300703007030c723007030c72300703007030070300703007030c723007030c72300703007030070300703007030c723107030c723
01240000150300c0300e03015000150301500013000150001503011000150300c03013030130000c03311000150300c000150001000011030100300e030150001503012000150000c00015030170000c03313000
012600001203015000000000000015030000000000000000120300000000000000001103000000000000000012030000000000000000100300000000000000000e03002000000000e00006030060300603506035
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
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
01 03044344
02 03054344
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

