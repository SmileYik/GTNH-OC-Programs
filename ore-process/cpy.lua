local args = { ... }

local copyMode = args[1]
local from = args[2]
local to = args[3]

print("rm -rf /mnt/"..to.."/*")
os.execute("rm -rf /mnt/"..to.."/*")
print("cp -r /mnt/"..from.."/* /mnt/"..to.."/")
os.execute("cp -r /mnt/"..from.."/* /mnt/"..to.."/")

if copyMode == "client" then
    print("echo 'client.lua' > /mnt/"..to.."/home/.shrc")
    os.execute("echo 'run-client.lua' > /mnt/"..to.."/home/.shrc")
end