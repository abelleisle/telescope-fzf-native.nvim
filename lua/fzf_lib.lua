local ffi = require "ffi"

local build_path = (function()
  local build_dir = "build"
  if string.match(package.path, "\\") then
    build_dir = build_dir.."_win_"
    build_dir = build_dir..os.getenv("PROCESSOR_ARCHITECTURE")
  else
    local sysf = io.popen("uname -p")
    if sysf then
      local arch = sysf:read("*a") or ""
      build_dir = build_dir.."_"..arch
      build_dir = string.gsub(build_dir, '^%s+', '')
      build_dir = string.gsub(build_dir, '%s+$', '')
      build_dir = string.gsub(build_dir, '[\n\r]+', ' ')
      sysf:close()
    end
  end
  return build_dir
end)()

local exists = function(file)
   local ok, err, code = os.rename(file, file)
   if not ok then
      if code == 13 then
         return true -- Permission denied, but it exists
      end
   end
   return ok, err
end

local isdir = function(path)
   -- "/" works on both Unix and Windows
   return exists(path.."/")
end

local library_path = (function()
  local dirname = string.sub(debug.getinfo(1).source, 2, #"/fzf_lib.lua" * -1)
  local lib_path = dirname .. "../"
  -- Check to see of arch specific build dir exists
  if isdir(lib_path .. build_path) then
    lib_path = lib_path .. build_path
  -- If not, fall back to default build dir. Note: this can still not exist
  else
    lib_path = lib_path .. "build"
  end

  -- Determine which library to load based on system
  if package.config:sub(1, 1) == "\\" then
    return lib_path .. "/libfzf.dll"
  else
    return lib_path .. "/libfzf.so"
  end
end)()
local native = ffi.load(library_path)

ffi.cdef [[
  typedef struct {} fzf_i16_t;
  typedef struct {} fzf_i32_t;
  typedef struct {
    fzf_i16_t I16;
    fzf_i32_t I32;
  } fzf_slab_t;

  typedef struct {} fzf_term_set_t;
  typedef struct {
    fzf_term_set_t **ptr;
    size_t size;
    size_t cap;
  } fzf_pattern_t;
  typedef struct {
    uint32_t *data;
    size_t size;
    size_t cap;
  } fzf_position_t;

  fzf_position_t *fzf_get_positions(const char *text, fzf_pattern_t *pattern, fzf_slab_t *slab);
  void fzf_free_positions(fzf_position_t *pos);
  int32_t fzf_get_score(const char *text, fzf_pattern_t *pattern, fzf_slab_t *slab);

  fzf_pattern_t *fzf_parse_pattern(int32_t case_mode, bool normalize, char *pattern, bool fuzzy);
  void fzf_free_pattern(fzf_pattern_t *pattern);

  fzf_slab_t *fzf_make_default_slab(void);
  void fzf_free_slab(fzf_slab_t *slab);
]]

local fzf = {}

fzf.build_path = build_path

fzf.get_score = function(input, pattern_struct, slab)
  return native.fzf_get_score(input, pattern_struct, slab)
end

fzf.get_pos = function(input, pattern_struct, slab)
  local pos = native.fzf_get_positions(input, pattern_struct, slab)
  if pos == nil then
    return
  end

  local res = {}
  for i = 1, tonumber(pos.size) do
    res[i] = pos.data[i - 1] + 1
  end
  native.fzf_free_positions(pos)

  return res
end

fzf.parse_pattern = function(pattern, case_mode, fuzzy)
  case_mode = case_mode == nil and 0 or case_mode
  fuzzy = fuzzy == nil and true or fuzzy
  local c_str = ffi.new("char[?]", #pattern + 1)
  ffi.copy(c_str, pattern)
  return native.fzf_parse_pattern(case_mode, false, c_str, fuzzy)
end

fzf.free_pattern = function(p)
  native.fzf_free_pattern(p)
end

fzf.allocate_slab = function()
  return native.fzf_make_default_slab()
end

fzf.free_slab = function(s)
  native.fzf_free_slab(s)
end

return fzf
