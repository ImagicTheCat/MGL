-- Benchmark math libraries.
-- Minimum of times / maximum of memory (maxrss)
-- (Lua 5.1)

local time_cmd = [[(command time -f "%e %U %M" $CMD) 2>&1]]
local function measure(cmd)
  cmd = time_cmd:gsub("%$CMD", cmd)
  local p = io.popen(cmd)
  local wtime, utime, mem = p:read("*a"):match("(%S+) (%S+) (%S+)")
  p:close()
  return tonumber(wtime), tonumber(utime), tonumber(mem)
end

-- cmd: command without bench arguments
-- its: iterations
local function bench(cmd, its, entities, ticks)
  cmd = cmd.." "..entities.." "..ticks
  print("bench", cmd)
  local a_wtime, a_utime, a_mem
  for i=1, its do
    local wtime, utime, mem = measure(cmd)
--    print(i, "wtime", wtime, "utime", utime, "mem", mem)
    a_wtime = math.min(a_wtime or wtime, wtime)
    a_utime = math.min(a_utime or utime, utime)
    a_mem = math.max(a_mem or mem, mem)
  end
  local ms_per_tick = a_wtime/ticks*1e3
  local pframe = math.floor(ms_per_tick/(1/60*1e3)*100+0.5)
  print("wtime (s)", "utime (s)", "mem (kB)", "~ms/tick", "~frame%")
  print(a_wtime, a_utime, a_mem, string.format("%.3f", ms_per_tick), pframe)
end

local its, entities, ticks = ...
its = tonumber(its) or 3
entities = tonumber(entities) or 5000
ticks = tonumber(ticks) or 1200
print("build")
os.execute("g++ -O2 glm/bench_transform.cpp -o glm_bench_transform")
print("benchmark ("..its.." iterations, "..entities.." entities and "..ticks.." ticks)")
bench("luajit ../examples/bench_transform.lua", its, entities, ticks)
bench("luajit -joff ../examples/bench_transform.lua", its, entities, ticks)
bench("luajit cpml/bench_transform.lua", its, entities, ticks)
bench("luajit -joff cpml/bench_transform.lua", its, entities, ticks)
bench("./glm_bench_transform", its, entities, ticks)
