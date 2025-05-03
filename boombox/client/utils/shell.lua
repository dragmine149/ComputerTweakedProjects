local make_package = dofile("rom/modules/main/cc/require.lua").make
local shellAdditions = {}

function shellAdditions.createShellEnv(dir)
    print("Creating shell environment...")
    local env = { shell = shell, multishell = multishell }
    env.require, env.package = make_package(env, dir)
    return env
end

return shellAdditions
