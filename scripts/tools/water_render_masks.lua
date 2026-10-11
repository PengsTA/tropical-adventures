local function h(s,n)local o,t,i=0,0,0
for a=1,9 do
local e=s[a]if e~=nil then
local a=2^(a-1)i=i+a
if e==n then o=o+a end
if e<=n then t=t+a end
end
end
local e=s[1]==n and 1 or 0
return e+t*2+i*1024,o
end
local function o(a,e,t)local e=math.floor(e/2+0.5)%4
local t=math.floor(t/2+0.5)%4
return a+512*(16+e+t*4)end
return{Build=h,PackTileCenter=o}