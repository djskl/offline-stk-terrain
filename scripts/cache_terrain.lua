--[[
结合try_files来使用，该脚本作为@fallback来使用
--]]

local CacheDir = ngx.var.cache_dir  --缓存目录

local args = ngx.req.get_uri_args()

local tx = tonumber(ngx.var.x)
local ty = tonumber(ngx.var.y)
local tz = tonumber(ngx.var.z)

if not (tx and ty and tz) then
    ngx.log(ngx.ERR, "x: ", ngx.var.x)
    ngx.log(ngx.ERR, "y: ", ngx.var.y)
    ngx.log(ngx.ERR, "z: ", ngx.var.z)
    ngx.exit(400)
end

local cache_tile_path = CacheDir..'/'..ngx.var.z..'/'..ngx.var.x
local cache_tile_file = cache_tile_path..'/'..ngx.var.y..'.terrain'

local fil = io.open(cache_tile_file)

if fil ~= nil then --为了避免死循环
        ngx.log(ngx.ERR, cache_tile_file, ' has existed!!!')
        ngx.exit(400)
end

local ret = ngx.location.capture(
    "/terrain_proxy",
    {args={x=tx, y=ty, z=tz}}
)

if 200 ~= ret.status then
    ngx.log(ngx.ERR, ret.body)
    ngx.exit(ret.status)
end


local ok_create = os.execute("mkdir -p "..cache_tile_path)
if not ok_create then
    ngx.log(ngx.ERR, "failed to make dir： ", cache_tile_path)
    ngx.exit(500)
end

local wf = io.open(cache_tile_file, "w")
wf:write(ret.body)
wf:close()

ngx.exec(ngx.var.request_uri)

