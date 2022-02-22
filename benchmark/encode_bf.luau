local BF = require("../src/BF")

local start = os.clock()

-- not sure if input should be put inside the loop or not \_(シ)_/

for i = 1, 1e6 do
    local bytecode = BF.compile(",[+++.,]")

    BF.to_ascii(
        BF.execute(bytecode, { string.byte("Hello, World!", 1, -1) })
    )
end

print(
    string.format(
        "Program finished executing in %.6f seconds",
        os.clock() - start
    )
)
