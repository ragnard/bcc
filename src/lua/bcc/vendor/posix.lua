--[[
Copyright 2016 GitHub, Inc

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
]]
local ffi = require("ffi")

ffi.cdef[[
typedef int clockid_t;
typedef long time_t;

struct timespec {
  time_t tv_sec;
  long tv_nsec;
};

int clock_gettime(clockid_t clk_id, struct timespec *tp);
int clock_nanosleep(clockid_t clock_id, int flags,
  const struct timespec *request, struct timespec *remain);

int get_nprocs(void);
]]

local CLOCK = {
  REALTIME                  = 0,
  MONOTONIC                 = 1,
  PROCESS_CPUTIME_ID        = 2,
  THREAD_CPUTIME_ID         = 3,
  MONOTONIC_RAW             = 4,
  REALTIME_COARSE           = 5,
  MONOTONIC_COARSE          = 6,
}

local function time_ns(clock)
  local ts = ffi.new("struct timespec[1]")
  assert(ffi.C.clock_gettime(clock or CLOCK.MONOTONIC_RAW, ts) == 0,
    "clock_gettime() failed: "..ffi.errno())
  return tonumber(ts[0].tv_sec * 1e9 + ts[0].tv_nsec)
end

local function sleep(seconds, clock)
  local s, ns = math.modf(seconds)
  local ts = ffi.new("struct timespec[1]")

  ts[0].tv_sec = s
  ts[0].tv_nsec = ns / 1e9

  ffi.C.clock_nanosleep(clock or CLOCK.MONOTONIC, 0, ts, nil)
end

local function cpu_count()
  return tonumber(ffi.C.get_nprocs())
end

return {
  time_ns=time_ns,
  sleep=sleep,
  CLOCK=CLOCK,
  cpu_count=cpu_count,
}
