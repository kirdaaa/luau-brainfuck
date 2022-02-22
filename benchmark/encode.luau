local function encode(string)
    local encoded = ""

    for _, byte in ipairs { string.byte(string, 1, -1) } do
        encoded ..= string.char(byte + 3)
    end

    return encoded
end

local start = os.clock()

for i = 1, 1e6 do
    encode("Hello, World!")
end

print(
    string.format(
        "Program finished executing in %.6f seconds",
        os.clock() - start
    )
)
