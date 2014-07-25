--[[
   hpbar.lua
   
   Copyright 2014 Victor Torres <vikthort.t@gmail.com>
   
   This program is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation; either version 2 of the License, or
   (at your option) any later version.
   
   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.
   
   You should have received a copy of the GNU General Public License
   along with this program; if not, write to the Free Software
   Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
   MA 02110-1301, USA.
   
]]--

settings = {
   {
      --The type of stat you would like to set for a HP bar
      name = 'cpu',
      --The argument(s) of the previous stat e.g. if you want to show in Conky ${cpu cpu0} cpu0 is what you would use here. If there's no args use ''.
      args = 'cpu0',
      --The minimum value to be considered. E.g. the value that will be considered 0% hp points
      min = 100,
      --The maximum value to be considered. E.g. the value that will be considered 100% hp points
      max = 0,
      --The type of the bar. A bar with type 1 would be used when min and max will be used as described above;
      --A bar type 0 would be used in the oposite way
      type = 0,
      --The model of the bar. It could be a large HP bar (model 3), the small one (model 2) or the mini (model 1)
      model = 1,
      --the coordinates of the HP Bar image, relative to the top left corner of the Conky window.
      coord_x = 0,
      coord_y = 85
   },
   {
      name = 'cpu',
      args = 'cpu1',
      min = 100,
      max = 0,
      type = 0,
      model = 1,
      coord_x = 0,
      coord_y = 120
   },
   {
      name = 'memperc',
      arg='',
      min = 100,
      max = 0,
      type = 0,
      model = 3,
      coord_x = 0,
      coord_y = 30
   },
   {
      name = 'swapperc',
      arg='',
      min = 100,
      max = 0,
      type = 0,
      model = 1,
      coord_x = 0,
      coord_y = 155
   }
}

require 'cairo'

function rgb_to_rgba(colour,alpha)
    return ((colour / 0x10000) % 0x100) / 255., ((colour / 0x100) % 0x100) / 255., (colour % 0x100) / 255., alpha
end

function normalize(v, max, min, type)      
   if v < min then v = min end
   if v > max then v = max end
   
   local porc = 100/(max-min)
   
   v = (v-min) * porc
   
   if(type == 0) then
      return 1- v/100
   end
   return v/100
end

function draw_bar(win, val_array)
   local w,h=conky_window.width,conky_window.height
   local str = ''
   local value = 0
   local bc = 0
   local alpha = 0
   local x, y, max, min = val_array['coord_x'], val_array['coord_y'], val_array['max'], val_array['min']
   local red, yellow = 0.20, 0.50
   local width, height = 0, 0
   if not (val_array['args'] == nil) then 
      str=string.format('${%s %s}',val_array['name'],val_array['args'])
   end
   if val_array['args'] == nil then
      str=string.format('${%s}',val_array['name'])
   end
	str=conky_parse(str)
   value=tonumber(str)
   
   if val_array['type'] == 0 then
      max = val_array['min']
      min = val_array['max']
   end
   value = normalize(value, max, min, val_array['type'])
   
   alpha = 0.9
   bc = 0x68c400                             --Green  color
   if value < yellow then bc = 0xe3ee23 end  --Yellow color
   if value < red then bc = 0xc92c3a end     --Red    color
   
   if val_array['model'] == 3 then
      --Draw the large status bar
      local desp = 89 + 287*value
      cairo_move_to(win, x+89, y+20)      
      cairo_line_to(win, x+desp, y+20)    
      --Draw the slim part of the bar (if needed)
      if desp > 244 then 
         cairo_line_to(win, x+desp-5, y+29)  
         cairo_line_to(win, x+239, y+29)  
         cairo_line_to(win, x+234, y+38)  
         cairo_line_to(win, x+89, y+38)      
      else
         cairo_line_to(win, x+desp-10, y+38)  
         cairo_line_to(win, x+89, y+38)      
      end
      cairo_close_path(win)
      cairo_fill(win)
      cairo_set_line_cap(win,CAIRO_LINE_CAP_BUTT)
      cairo_set_line_width(win,1)
      cairo_set_source_rgba(win,rgb_to_rgba(bc,alpha))
      cairo_stroke(win)
   elseif val_array['model'] == 2 then 
      --Draw the small status bar 
      local desp = 137 + 173*value
      cairo_move_to(win, x+137, y+20)
      cairo_line_to(win, x+desp+5, y+20)
      cairo_line_to(win, x+desp, y+35)
      cairo_line_to(win, x+137, y+35)
      cairo_close_path(win)
      cairo_set_line_cap(win,CAIRO_LINE_CAP_BUTT)
      cairo_set_line_width(win,1)
      cairo_set_source_rgba(win,rgb_to_rgba(bc,alpha))
      cairo_fill(win)
      cairo_stroke(win)
   elseif val_array['model'] == 1 then 
      --Draw the mini status bar 
      local desp = 91 + 121*value
      cairo_move_to(win, x+91, y+14)
      cairo_line_to(win, x+desp+3, y+14)
      cairo_line_to(win, x+desp, y+26)
      cairo_line_to(win, x+91, y+26)
      cairo_close_path(win)
      cairo_set_line_cap(win,CAIRO_LINE_CAP_BUTT)
      cairo_set_line_width(win,1)
      cairo_set_source_rgba(win,rgb_to_rgba(bc,alpha))
      cairo_fill(win)
      cairo_stroke(win)
   end
end

function conky_hpbar()
   
   if conky_window==nil then return end
   
   local cs=cairo_xlib_surface_create(conky_window.display,conky_window.drawable,conky_window.visual, conky_window.width,conky_window.height)
   
   local cr=cairo_create(cs)    

   local updates=conky_parse('${updates}')
   local update_num=tonumber(updates)

   if update_num>5 then
     for i in pairs(settings) do
         draw_bar(cr,settings[i])
     end
   end
   
end
