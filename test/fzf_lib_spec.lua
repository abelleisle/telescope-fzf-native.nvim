local fzf = require("fzf_lib")
local eq = assert.are.same

describe("fzf", function()
  local slab = fzf.allocate_slab()
  it("can get the score for simple pattern", function()
    local p = fzf.parse_pattern("fzf", 0)
    eq(80, fzf.get_score("src/fzf", p, slab))
    eq(0, fzf.get_score("asdf", p, slab))
    eq(50, fzf.get_score("fasdzasdf", p, slab))
    fzf.free_pattern(p)
  end)

  it("can get the score for or pattern", function()
    local p = fzf.parse_pattern("lua | src | 'doc | ^asdfasdf | file$", 0)
    eq(80, fzf.get_score("src/fzf.c", p, slab))
    eq(0, fzf.get_score("build/libfzf", p, slab))
    eq(80, fzf.get_score("lua/fzf_lib.lua", p, slab))
    eq(80, fzf.get_score("doc/fzf.txt", p, slab))
    eq(0, fzf.get_score("daonc/fzf.txt", p, slab))
    eq(200, fzf.get_score("asdfasdf", p, slab))
    eq(0, fzf.get_score("noasdfasdf", p, slab))
    eq(104, fzf.get_score("not_file", p, slab))
    eq(0, fzf.get_score("not_file.txt", p, slab))
    fzf.free_pattern(p)
  end)

  it("can get the score for and pattern", function()
    local p = fzf.parse_pattern("fzf !lib", 0)
    eq(80, fzf.get_score("src/fzf.c", p, slab))
    eq(0, fzf.get_score("lua/fzf_lib.lua", p, slab))
    eq(0, fzf.get_score("build/libfzf", p, slab))
    fzf.free_pattern(p)

    local p = fzf.parse_pattern("fzf src c", 0)
    eq(192, fzf.get_score("src/fzf.c", p, slab))
    eq(0, fzf.get_score("lua/fzf_lib.lua", p, slab))
    eq(0, fzf.get_score("build/libfzf", p, slab))
    fzf.free_pattern(p)
  end)

  it("can get the score for patterns with escaped space", function()
    local p = fzf.parse_pattern("\\ ", 0)
    eq(32, fzf.get_score("src file", p, slab))
    eq(0, fzf.get_score("src_file", p, slab))
    eq(32, fzf.get_score("another another file", p, slab))
    fzf.free_pattern(p)
  end)

  it("can get the pos for simple pattern", function()
    local p = fzf.parse_pattern("fzf", 0)
    eq({ 7, 6, 5}, fzf.get_pos("src/fzf", p, slab))
    eq({}, fzf.get_pos("asdf", p, slab))
    eq({9, 5, 1}, fzf.get_pos("fasdzasdf", p, slab))
    fzf.free_pattern(p)
  end)

  it("can get the pos for or pattern", function()
    local p = fzf.parse_pattern("lua | src | 'doc | ^asdfasdf | file$", 0)
    eq({ 3, 2, 1}, fzf.get_pos("src/fzf.c", p, slab))
    eq({}, fzf.get_pos("build/libfzf", p, slab))
    eq({3, 2, 1}, fzf.get_pos("lua/fzf_lib.lua", p, slab))
    eq({1, 2, 3}, fzf.get_pos("doc/fzf.txt", p, slab))
    eq({}, fzf.get_pos("daonc/fzf.txt", p, slab))
    eq({1, 2, 3, 4, 5, 6, 7, 8}, fzf.get_pos("asdfasdf", p, slab))
    eq({}, fzf.get_pos("noasdfasdf", p, slab))
    eq({ 5, 6, 7, 8}, fzf.get_pos("not_file", p, slab))
    eq({}, fzf.get_pos("not_file.txt", p, slab))
    fzf.free_pattern(p)
  end)

  it("can get the pos for and pattern", function()
    local p = fzf.parse_pattern("fzf !lib", 0)
    eq({7, 6, 5}, fzf.get_pos("src/fzf.c", p, slab))
    eq({}, fzf.get_pos("lua/fzf_lib.lua", p, slab))
    eq({}, fzf.get_pos("build/libfzf", p, slab))
    fzf.free_pattern(p)

    p = fzf.parse_pattern("fzf src c", 0)
    eq({7, 6, 5, 3, 2, 1, 9}, fzf.get_pos("src/fzf.c", p, slab))
    eq({}, fzf.get_pos("lua/fzf_lib.lua", p, slab))
    eq({}, fzf.get_pos("build/libfzf", p, slab))
    fzf.free_pattern(p)
  end)

  it("can get the pos for patterns with escaped space", function()
    local p = fzf.parse_pattern("\\ ", 0)
    eq({4}, fzf.get_pos("src file", p, slab))
    eq({}, fzf.get_pos("src_file", p, slab))
    eq({8}, fzf.get_pos("another another file", p, slab))
    fzf.free_pattern(p)
  end)
  fzf.free_slab(slab)
end)
