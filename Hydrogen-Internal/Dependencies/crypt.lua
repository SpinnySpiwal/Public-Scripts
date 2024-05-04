--> AESLua in One File, for use with Hydrogen <--

local public, private, util, gf, aes, ciphermode, crypt = {}, {}, {}, {}, {}, {}, {}
local bit = bit32

--> util.lua <--

--
-- calculate the parity of one byte
--
function util.byteParity(byte)
	byte = bit.bxor(byte, bit.rshift(byte, 4))
	byte = bit.bxor(byte, bit.rshift(byte, 2))
	byte = bit.bxor(byte, bit.rshift(byte, 1))
	return bit.band(byte, 1)
end

--
-- get byte at position index
--
function util.getByte(number, index)
	if index == 0 then
		return bit.band(number, 0xff)
	else
		return bit.band(bit.rshift(number, index * 8), 0xff)
	end
end

--
-- put number into int at position index
--
function util.putByte(number, index)
	if index == 0 then
		return bit.band(number, 0xff)
	else
		return bit.lshift(bit.band(number, 0xff), index * 8)
	end
end

--
-- convert byte array to int array
--
function util.bytesToInts(bytes, start, n)
	local ints = {}
	for i = 0, n - 1 do
		ints[i] = util.putByte(bytes[start + (i * 4)], 3)
			+ util.putByte(bytes[start + (i * 4) + 1], 2)
			+ util.putByte(bytes[start + (i * 4) + 2], 1)
			+ util.putByte(bytes[start + (i * 4) + 3], 0)
	end
	return ints
end

--
-- convert int array to byte array
--
function util.intsToBytes(ints, output, outputOffset, n)
	n = n or #ints
	for i = 0, n do
		for j = 0, 3 do
			output[outputOffset + i * 4 + (3 - j)] = util.getByte(ints[i], j)
		end
	end
	return output
end

--
-- convert bytes to hexString
--
function private.bytesToHex(bytes)
	local hexBytes = ""

	for _, byte in ipairs(bytes) do
		hexBytes = hexBytes .. string.format("%02x ", byte)
	end

	return hexBytes
end

--
-- convert data to hex string
--
function util.toHexString(data)
	local type = type(data)
	if type == "number" then
		return string.format("%08x", data)
	elseif type == "table" then
		return private.bytesToHex(data)
	elseif type == "string" then
		local bytes = { string.byte(data, 1, #data) }

		return private.bytesToHex(bytes)
	else
		return data
	end
end

function util.padByteString(data)
	local dataLength = #data

	local random1 = math.random(0, 255)
	local random2 = math.random(0, 255)

	local prefix = string.char(
		random1,
		random2,
		random1,
		random2,
		util.getByte(dataLength, 3),
		util.getByte(dataLength, 2),
		util.getByte(dataLength, 1),
		util.getByte(dataLength, 0)
	)

	data = prefix .. data

	local paddingLength = math.ceil(#data / 16) * 16 - #data
	local padding = ""
	for _ = 1, paddingLength do
		padding = padding .. string.char(math.random(0, 255))
	end

	return data .. padding
end

function private.properlyDecrypted(data)
	local random = { string.byte(data, 1, 4) }

	if random[1] == random[3] and random[2] == random[4] then
		return true
	end

	return false
end

function util.unpadByteString(data)
	if not private.properlyDecrypted(data) then
		return nil
	end

	local dataLength = util.putByte(string.byte(data, 5), 3)
		+ util.putByte(string.byte(data, 6), 2)
		+ util.putByte(string.byte(data, 7), 1)
		+ util.putByte(string.byte(data, 8), 0)

	return string.sub(data, 9, 8 + dataLength)
end

function util.xorIV(data, iv)
	for i = 1, 16 do
		data[i] = bit.bxor(data[i], iv[i])
	end
end

--> Buffer.lua <--
local buffer = {}
function buffer.new()
	return {}
end

function buffer.addString(stack, s)
	table.insert(stack, s)
	for i = #stack - 1, 1, -1 do
		if #stack[i] > #stack[i + 1] then
			break
		end
		stack[i] = stack[i] .. table.remove(stack)
	end
end

function buffer.toString(stack)
	for i = #stack - 1, 1, -1 do
		stack[i] = stack[i] .. table.remove(stack)
	end
	return stack[1]
end

--> gf <--

-- private data of gf
private.n = 0x100
private.ord = 0xff
private.irrPolynom = 0x11b
private.exp = {}
private.log = {}

--
-- add two polynoms (its simply xor)
--
function gf.add(operand1, operand2)
	return bit.bxor(operand1, operand2)
end

--
-- subtract two polynoms (same as addition)
--
function gf.sub(operand1, operand2)
	return bit.bxor(operand1, operand2)
end

--
-- inverts element
-- a^(-1) = g^(order - log(a))
--
function gf.invert(operand)
	-- special case for 1
	if operand == 1 then
		return 1
	end
	-- normal invert
	local exponent = private.ord - private.log[operand]
	return private.exp[exponent]
end

--
-- multiply two elements using a logarithm table
-- a*b = g^(log(a)+log(b))
--
function gf.mul(operand1, operand2)
	if operand1 == 0 or operand2 == 0 then
		return 0
	end

	local exponent = private.log[operand1] + private.log[operand2]
	if exponent >= private.ord then
		exponent = exponent - private.ord
	end
	return private.exp[exponent]
end

--
-- divide two elements
-- a/b = g^(log(a)-log(b))
--
function gf.div(operand1, operand2)
	if operand1 == 0 then
		return 0
	end
	-- TODO: exception if operand2 == 0
	local exponent = private.log[operand1] - private.log[operand2]
	if exponent < 0 then
		exponent = exponent + private.ord
	end
	return private.exp[exponent]
end

--
-- print logarithmic table
--
function gf.printLog()
	for i = 1, private.n do
		print("log(", i - 1, ")=", private.log[i - 1])
	end
end

--
-- print exponentiation table
--
function gf.printExp()
	for i = 1, private.n do
		print("exp(", i - 1, ")=", private.exp[i - 1])
	end
end

--
-- calculate logarithmic and exponentiation table
--
function private.initMulTable()
	local a = 1

	for i = 0, private.ord - 1 do
		private.exp[i] = a
		private.log[a] = i

		-- multiply with generator x+1 -> left shift + 1
		a = bit.bxor(bit.lshift(a, 1), a)

		-- if a gets larger than order, reduce modulo irreducible polynom
		if a > private.ord then
			a = gf.sub(a, private.irrPolynom)
		end
	end
end

private.initMulTable()

--> AES.lua <--

--
-- Implementation of AES with nearly pure lua (only bitlib is needed)
--
-- AES with lua is slow, really slow :-)
--

-- some constants
aes.ROUNDS = "rounds"
aes.KEY_TYPE = "type"
aes.ENCRYPTION_KEY = 1
aes.DECRYPTION_KEY = 2

-- aes SBOX
private.SBox = {}
private.iSBox = {}

-- aes tables
private.table0 = {}
private.table1 = {}
private.table2 = {}
private.table3 = {}

private.tableInv0 = {}
private.tableInv1 = {}
private.tableInv2 = {}
private.tableInv3 = {}

-- round constants
private.rCon = {
	0x01000000,
	0x02000000,
	0x04000000,
	0x08000000,
	0x10000000,
	0x20000000,
	0x40000000,
	0x80000000,
	0x1b000000,
	0x36000000,
	0x6c000000,
	0xd8000000,
	0xab000000,
	0x4d000000,
	0x9a000000,
	0x2f000000,
}

--
-- affine transformation for calculating the S-Box of AES
--
function private.affinMap(byte)
	mask = 0xf8
	result = 0
	for _ = 1, 8 do
		result = bit.lshift(result, 1)

		parity = util.byteParity(bit.band(byte, mask))
		result = result + parity

		-- simulate roll
		lastbit = bit.band(mask, 1)
		mask = bit.band(bit.rshift(mask, 1), 0xff)
		if lastbit ~= 0 then
			mask = bit.bor(mask, 0x80)
		else
			mask = bit.band(mask, 0x7f)
		end
	end

	return bit.bxor(result, 0x63)
end

--
-- calculate S-Box and inverse S-Box of AES
-- apply affine transformation to inverse in finite field 2^8
--
function private.calcSBox()
	for i = 0, 255 do
		if i ~= 0 then
			inverse = gf.invert(i)
		else
			inverse = i
		end
		mapped = private.affinMap(inverse)
		private.SBox[i] = mapped
		private.iSBox[mapped] = i
	end
end

--
-- Calculate round tables
-- round tables are used to calculate shiftRow, MixColumn and SubBytes
-- with 4 table lookups and 4 xor operations.
--
function private.calcRoundTables()
	for x = 0, 255 do
		byte = private.SBox[x]
		private.table0[x] = util.putByte(gf.mul(0x03, byte), 0)
			+ util.putByte(byte, 1)
			+ util.putByte(byte, 2)
			+ util.putByte(gf.mul(0x02, byte), 3)
		private.table1[x] = util.putByte(byte, 0)
			+ util.putByte(byte, 1)
			+ util.putByte(gf.mul(0x02, byte), 2)
			+ util.putByte(gf.mul(0x03, byte), 3)
		private.table2[x] = util.putByte(byte, 0)
			+ util.putByte(gf.mul(0x02, byte), 1)
			+ util.putByte(gf.mul(0x03, byte), 2)
			+ util.putByte(byte, 3)
		private.table3[x] = util.putByte(gf.mul(0x02, byte), 0)
			+ util.putByte(gf.mul(0x03, byte), 1)
			+ util.putByte(byte, 2)
			+ util.putByte(byte, 3)
	end
end

--
-- Calculate inverse round tables
-- does the inverse of the normal roundtables for the equivalent
-- decryption algorithm.
--
function private.calcInvRoundTables()
	for x = 0, 255 do
		local byte = private.iSBox[x]
		private.tableInv0[x] = util.putByte(gf.mul(0x0b, byte), 0)
			+ util.putByte(gf.mul(0x0d, byte), 1)
			+ util.putByte(gf.mul(0x09, byte), 2)
			+ util.putByte(gf.mul(0x0e, byte), 3)
		private.tableInv1[x] = util.putByte(gf.mul(0x0d, byte), 0)
			+ util.putByte(gf.mul(0x09, byte), 1)
			+ util.putByte(gf.mul(0x0e, byte), 2)
			+ util.putByte(gf.mul(0x0b, byte), 3)
		private.tableInv2[x] = util.putByte(gf.mul(0x09, byte), 0)
			+ util.putByte(gf.mul(0x0e, byte), 1)
			+ util.putByte(gf.mul(0x0b, byte), 2)
			+ util.putByte(gf.mul(0x0d, byte), 3)
		private.tableInv3[x] = util.putByte(gf.mul(0x0e, byte), 0)
			+ util.putByte(gf.mul(0x0b, byte), 1)
			+ util.putByte(gf.mul(0x0d, byte), 2)
			+ util.putByte(gf.mul(0x09, byte), 3)
	end
end

--
-- rotate word: 0xaabbccdd gets 0xbbccddaa
-- used for key schedule
--
function private.rotWord(word)
	local tmp = bit.band(word, 0xff000000)
	return (bit.lshift(word, 8) + bit.rshift(tmp, 24))
end

--
-- replace all bytes in a word with the SBox.
-- used for key schedule
--
function private.subWord(word)
	return util.putByte(private.SBox[util.getByte(word, 0)], 0)
		+ util.putByte(private.SBox[util.getByte(word, 1)], 1)
		+ util.putByte(private.SBox[util.getByte(word, 2)], 2)
		+ util.putByte(private.SBox[util.getByte(word, 3)], 3)
end

--
-- generate key schedule for aes encryption
--
-- returns table with all round keys and
-- the necessary number of rounds saved in [aes.ROUNDS]
--
function aes.expandEncryptionKey(key)
	local keySchedule = {}
	local keyWords = math.floor(#key / 4)

	if (keyWords ~= 4 and keyWords ~= 6 and keyWords ~= 8) or (keyWords * 4 ~= #key) then
		print("Invalid key size: ", keyWords)
		return nil
	end

	keySchedule[aes.ROUNDS] = keyWords + 6
	keySchedule[aes.KEY_TYPE] = aes.ENCRYPTION_KEY

	for i = 0, keyWords - 1 do
		keySchedule[i] = util.putByte(key[i * 4 + 1], 3)
			+ util.putByte(key[i * 4 + 2], 2)
			+ util.putByte(key[i * 4 + 3], 1)
			+ util.putByte(key[i * 4 + 4], 0)
	end

	for i = keyWords, (keySchedule[aes.ROUNDS] + 1) * 4 - 1 do
		local tmp = keySchedule[i - 1]

		if i % keyWords == 0 then
			tmp = private.rotWord(tmp)
			tmp = private.subWord(tmp)

			local index = math.floor(i / keyWords)
			tmp = bit.bxor(tmp, private.rCon[index])
		elseif keyWords > 6 and i % keyWords == 4 then
			tmp = private.subWord(tmp)
		end

		keySchedule[i] = bit.bxor(keySchedule[(i - keyWords)], tmp)
	end

	return keySchedule
end

--
-- Inverse mix column
-- used for key schedule of decryption key
--
function private.invMixColumnOld(word)
	local b0 = util.getByte(word, 3)
	local b1 = util.getByte(word, 2)
	local b2 = util.getByte(word, 1)
	local b3 = util.getByte(word, 0)

	return util.putByte(
		gf.add(gf.add(gf.add(gf.mul(0x0b, b1), gf.mul(0x0d, b2)), gf.mul(0x09, b3)), gf.mul(0x0e, b0)),
		3
	) + util.putByte(gf.add(gf.add(gf.add(gf.mul(0x0b, b2), gf.mul(0x0d, b3)), gf.mul(0x09, b0)), gf.mul(0x0e, b1)), 2) + util.putByte(
		gf.add(gf.add(gf.add(gf.mul(0x0b, b3), gf.mul(0x0d, b0)), gf.mul(0x09, b1)), gf.mul(0x0e, b2)),
		1
	) + util.putByte(gf.add(gf.add(gf.add(gf.mul(0x0b, b0), gf.mul(0x0d, b1)), gf.mul(0x09, b2)), gf.mul(0x0e, b3)), 0)
end

--
-- Optimized inverse mix column
-- look at http://fp.gladman.plus.com/cryptography_technology/rijndael/aes.spec.311.pdf
-- TODO: make it work
--
function private.invMixColumn(word)
	local b0 = util.getByte(word, 3)
	local b1 = util.getByte(word, 2)
	local b2 = util.getByte(word, 1)
	local b3 = util.getByte(word, 0)

	local t = bit.bxor(b3, b2)
	local u = bit.bxor(b1, b0)
	local v = bit.bxor(t, u)
	v = bit.bxor(v, gf.mul(0x08, v))
	w = bit.bxor(v, gf.mul(0x04, bit.bxor(b2, b0)))
	v = bit.bxor(v, gf.mul(0x04, bit.bxor(b3, b1)))

	return util.putByte(bit.bxor(bit.bxor(b3, v), gf.mul(0x02, bit.bxor(b0, b3))), 0)
		+ util.putByte(bit.bxor(bit.bxor(b2, w), gf.mul(0x02, t)), 1)
		+ util.putByte(bit.bxor(bit.bxor(b1, v), gf.mul(0x02, bit.bxor(b0, b3))), 2)
		+ util.putByte(bit.bxor(bit.bxor(b0, w), gf.mul(0x02, u)), 3)
end

--
-- generate key schedule for aes decryption
--
-- uses key schedule for aes encryption and transforms each
-- key by inverse mix column.
--
function aes.expandDecryptionKey(key)
	local keySchedule = aes.expandEncryptionKey(key)
	if keySchedule == nil then
		return nil
	end

	keySchedule[aes.KEY_TYPE] = aes.DECRYPTION_KEY

	for i = 4, (keySchedule[aes.ROUNDS] + 1) * 4 - 5 do
		keySchedule[i] = private.invMixColumnOld(keySchedule[i])
	end

	return keySchedule
end

--
-- xor round key to state
--
function private.addRoundKey(state, key, round)
	for i = 0, 3 do
		state[i] = bit.bxor(state[i], key[round * 4 + i])
	end
end

--
-- do encryption round (ShiftRow, SubBytes, MixColumn together)
--
function private.doRound(origState, dstState)
	dstState[0] = bit.bxor(
		bit.bxor(
			bit.bxor(private.table0[util.getByte(origState[0], 3)], private.table1[util.getByte(origState[1], 2)]),
			private.table2[util.getByte(origState[2], 1)]
		),
		private.table3[util.getByte(origState[3], 0)]
	)

	dstState[1] = bit.bxor(
		bit.bxor(
			bit.bxor(private.table0[util.getByte(origState[1], 3)], private.table1[util.getByte(origState[2], 2)]),
			private.table2[util.getByte(origState[3], 1)]
		),
		private.table3[util.getByte(origState[0], 0)]
	)

	dstState[2] = bit.bxor(
		bit.bxor(
			bit.bxor(private.table0[util.getByte(origState[2], 3)], private.table1[util.getByte(origState[3], 2)]),
			private.table2[util.getByte(origState[0], 1)]
		),
		private.table3[util.getByte(origState[1], 0)]
	)

	dstState[3] = bit.bxor(
		bit.bxor(
			bit.bxor(private.table0[util.getByte(origState[3], 3)], private.table1[util.getByte(origState[0], 2)]),
			private.table2[util.getByte(origState[1], 1)]
		),
		private.table3[util.getByte(origState[2], 0)]
	)
end

--
-- do last encryption round (ShiftRow and SubBytes)
--
function private.doLastRound(origState, dstState)
	dstState[0] = util.putByte(private.SBox[util.getByte(origState[0], 3)], 3)
		+ util.putByte(private.SBox[util.getByte(origState[1], 2)], 2)
		+ util.putByte(private.SBox[util.getByte(origState[2], 1)], 1)
		+ util.putByte(private.SBox[util.getByte(origState[3], 0)], 0)

	dstState[1] = util.putByte(private.SBox[util.getByte(origState[1], 3)], 3)
		+ util.putByte(private.SBox[util.getByte(origState[2], 2)], 2)
		+ util.putByte(private.SBox[util.getByte(origState[3], 1)], 1)
		+ util.putByte(private.SBox[util.getByte(origState[0], 0)], 0)

	dstState[2] = util.putByte(private.SBox[util.getByte(origState[2], 3)], 3)
		+ util.putByte(private.SBox[util.getByte(origState[3], 2)], 2)
		+ util.putByte(private.SBox[util.getByte(origState[0], 1)], 1)
		+ util.putByte(private.SBox[util.getByte(origState[1], 0)], 0)

	dstState[3] = util.putByte(private.SBox[util.getByte(origState[3], 3)], 3)
		+ util.putByte(private.SBox[util.getByte(origState[0], 2)], 2)
		+ util.putByte(private.SBox[util.getByte(origState[1], 1)], 1)
		+ util.putByte(private.SBox[util.getByte(origState[2], 0)], 0)
end

--
-- do decryption round
--
function private.doInvRound(origState, dstState)
	dstState[0] = bit.bxor(
		bit.bxor(
			bit.bxor(private.tableInv0[util.getByte(origState[0], 3)], private.tableInv1[util.getByte(origState[3], 2)]),
			private.tableInv2[util.getByte(origState[2], 1)]
		),
		private.tableInv3[util.getByte(origState[1], 0)]
	)

	dstState[1] = bit.bxor(
		bit.bxor(
			bit.bxor(private.tableInv0[util.getByte(origState[1], 3)], private.tableInv1[util.getByte(origState[0], 2)]),
			private.tableInv2[util.getByte(origState[3], 1)]
		),
		private.tableInv3[util.getByte(origState[2], 0)]
	)

	dstState[2] = bit.bxor(
		bit.bxor(
			bit.bxor(private.tableInv0[util.getByte(origState[2], 3)], private.tableInv1[util.getByte(origState[1], 2)]),
			private.tableInv2[util.getByte(origState[0], 1)]
		),
		private.tableInv3[util.getByte(origState[3], 0)]
	)

	dstState[3] = bit.bxor(
		bit.bxor(
			bit.bxor(private.tableInv0[util.getByte(origState[3], 3)], private.tableInv1[util.getByte(origState[2], 2)]),
			private.tableInv2[util.getByte(origState[1], 1)]
		),
		private.tableInv3[util.getByte(origState[0], 0)]
	)
end

--
-- do last decryption round
--
function private.doInvLastRound(origState, dstState)
	dstState[0] = util.putByte(private.iSBox[util.getByte(origState[0], 3)], 3)
		+ util.putByte(private.iSBox[util.getByte(origState[3], 2)], 2)
		+ util.putByte(private.iSBox[util.getByte(origState[2], 1)], 1)
		+ util.putByte(private.iSBox[util.getByte(origState[1], 0)], 0)

	dstState[1] = util.putByte(private.iSBox[util.getByte(origState[1], 3)], 3)
		+ util.putByte(private.iSBox[util.getByte(origState[0], 2)], 2)
		+ util.putByte(private.iSBox[util.getByte(origState[3], 1)], 1)
		+ util.putByte(private.iSBox[util.getByte(origState[2], 0)], 0)

	dstState[2] = util.putByte(private.iSBox[util.getByte(origState[2], 3)], 3)
		+ util.putByte(private.iSBox[util.getByte(origState[1], 2)], 2)
		+ util.putByte(private.iSBox[util.getByte(origState[0], 1)], 1)
		+ util.putByte(private.iSBox[util.getByte(origState[3], 0)], 0)

	dstState[3] = util.putByte(private.iSBox[util.getByte(origState[3], 3)], 3)
		+ util.putByte(private.iSBox[util.getByte(origState[2], 2)], 2)
		+ util.putByte(private.iSBox[util.getByte(origState[1], 1)], 1)
		+ util.putByte(private.iSBox[util.getByte(origState[0], 0)], 0)
end

--
-- encrypts 16 Bytes
-- key           encryption key schedule
-- input         array with input data
-- inputOffset   start index for input
-- output        array for encrypted data
-- outputOffset  start index for output
--
function aes.encrypt(key, input, inputOffset, output, outputOffset)
	--default parameters
	inputOffset = inputOffset or 1
	output = output or {}
	outputOffset = outputOffset or 1

	local state = {}
	local tmpState = {}

	if key[aes.KEY_TYPE] ~= aes.ENCRYPTION_KEY then
		print("No encryption key: ", key[aes.KEY_TYPE])
		return
	end

	state = util.bytesToInts(input, inputOffset, 4)
	private.addRoundKey(state, key, 0)

	local round = 1
	while round < key[aes.ROUNDS] - 1 do
		-- do a double round to save temporary assignments
		private.doRound(state, tmpState)
		private.addRoundKey(tmpState, key, round)
		round = round + 1

		private.doRound(tmpState, state)
		private.addRoundKey(state, key, round)
		round = round + 1
	end

	private.doRound(state, tmpState)
	private.addRoundKey(tmpState, key, round)
	round = round + 1

	private.doLastRound(tmpState, state)
	private.addRoundKey(state, key, round)

	return util.intsToBytes(state, output, outputOffset)
end

--
-- decrypt 16 bytes
-- key           decryption key schedule
-- input         array with input data
-- inputOffset   start index for input
-- output        array for decrypted data
-- outputOffset  start index for output
---
function aes.decrypt(key, input, inputOffset, output, outputOffset)
	-- default arguments
	inputOffset = inputOffset or 1
	output = output or {}
	outputOffset = outputOffset or 1

	local state = {}
	local tmpState = {}

	if key[aes.KEY_TYPE] ~= aes.DECRYPTION_KEY then
		print("No decryption key: ", key[aes.KEY_TYPE])
		return
	end

	state = util.bytesToInts(input, inputOffset, 4)
	private.addRoundKey(state, key, key[aes.ROUNDS])

	local round = key[aes.ROUNDS] - 1
	while round > 2 do
		-- do a double round to save temporary assignments
		private.doInvRound(state, tmpState)
		private.addRoundKey(tmpState, key, round)
		round = round - 1

		private.doInvRound(tmpState, state)
		private.addRoundKey(state, key, round)
		round = round - 1
	end

	private.doInvRound(state, tmpState)
	private.addRoundKey(tmpState, key, round)
	round = round - 1

	private.doInvLastRound(tmpState, state)
	private.addRoundKey(state, key, round)

	return util.intsToBytes(state, output, outputOffset)
end

-- calculate all tables when loading this file
private.calcSBox()
private.calcRoundTables()
private.calcInvRoundTables()

--> CipherMode <--

--
-- Encrypt strings
-- key - byte array with key
-- string - string to encrypt
-- modefunction - function for cipher mode to use
--
function ciphermode.encryptString(key, data, modeFunction)
	local iv = iv or { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 }
	local keySched = aes.expandEncryptionKey(key)
	local encryptedData = buffer.new()

	for i = 1, #data / 16 do
		local offset = (i - 1) * 16 + 1
		local byteData = { string.byte(data, offset, offset + 15) }

		modeFunction(keySched, byteData, iv)

		buffer.addString(encryptedData, string.char(unpack(byteData)))
	end

	return buffer.toString(encryptedData)
end

--
-- the following 4 functions can be used as
-- modefunction for encryptString
--

-- Electronic code book mode encrypt function
function ciphermode.encryptECB(keySched, byteData, _)
	aes.encrypt(keySched, byteData, 1, byteData, 1)
end

-- Cipher block chaining mode encrypt function
function ciphermode.encryptCBC(keySched, byteData, iv)
	util.xorIV(byteData, iv)

	aes.encrypt(keySched, byteData, 1, byteData, 1)

	for j = 1, 16 do
		iv[j] = byteData[j]
	end
end

-- Output feedback mode encrypt function
function ciphermode.encryptOFB(keySched, byteData, iv)
	aes.encrypt(keySched, iv, 1, iv, 1)
	util.xorIV(byteData, iv)
end

-- Cipher feedback mode encrypt function
function ciphermode.encryptCFB(keySched, byteData, iv)
	aes.encrypt(keySched, iv, 1, iv, 1)
	util.xorIV(byteData, iv)

	for j = 1, 16 do
		iv[j] = byteData[j]
	end
end

--
-- Decrypt strings
-- key - byte array with key
-- string - string to decrypt
-- modefunction - function for cipher mode to use
--
function ciphermode.decryptString(key, data, modeFunction)
	local iv = iv or { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 }

	local keySched
	if modeFunction == ciphermode.decryptOFB or modeFunction == ciphermode.decryptCFB then
		keySched = aes.expandEncryptionKey(key)
	else
		keySched = aes.expandDecryptionKey(key)
	end

	local decryptedData = buffer.new()

	for i = 1, #data / 16 do
		local offset = (i - 1) * 16 + 1
		local byteData = { string.byte(data, offset, offset + 15) }

		iv = modeFunction(keySched, byteData, iv)

		buffer.addString(decryptedData, string.char(unpack(byteData)))
	end

	return buffer.toString(decryptedData)
end

--
-- the following 4 functions can be used as
-- modefunction for decryptString
--

-- Electronic code book mode decrypt function
function ciphermode.decryptECB(keySched, byteData, iv)
	aes.decrypt(keySched, byteData, 1, byteData, 1)

	return iv
end

-- Cipher block chaining mode decrypt function
function ciphermode.decryptCBC(keySched, byteData, iv)
	local nextIV = {}
	for j = 1, 16 do
		nextIV[j] = byteData[j]
	end

	aes.decrypt(keySched, byteData, 1, byteData, 1)
	util.xorIV(byteData, iv)

	return nextIV
end

-- Output feedback mode decrypt function
function ciphermode.decryptOFB(keySched, byteData, iv)
	aes.encrypt(keySched, iv, 1, iv, 1)
	util.xorIV(byteData, iv)

	return iv
end

-- Cipher feedback mode decrypt function
function ciphermode.decryptCFB(keySched, byteData, iv)
	local nextIV = {}
	for j = 1, 16 do
		nextIV[j] = byteData[j]
	end

	aes.encrypt(keySched, iv, 1, iv, 1)

	util.xorIV(byteData, iv)

	return nextIV
end

--
-- Simple API for encrypting strings.
--

public.AES128 = 16
public.AES192 = 24
public.AES256 = 32

public.ECBMODE = "ECB"
public.CBCMODE = "CBC"
public.OFBMODE = "OFB"
public.CFBMODE = "CFB"

function private.pwToKey(password, keyLength)
	local padLength = keyLength
	if keyLength == public.AES192 then
		padLength = 32
	end

	if padLength > #password then
		local postfix = ""
		for _ = 1, padLength - #password do
			postfix = postfix .. string.char(0)
		end
		password = password .. postfix
	else
		password = string.sub(password, 1, padLength)
	end

	local pwBytes = { string.byte(password, 1, #password) }
	password = ciphermode.encryptString(pwBytes, password, ciphermode.encryptCBC)

	password = string.sub(password, 1, keyLength)

	return { string.byte(password, 1, #password) }
end

--
-- Encrypts string data with password password.
-- password  - the encryption key is generated from this string
-- data      - string to encrypt (must not be too large)
-- keyLength - length of aes key: 128(default), 192 or 256 Bit
-- mode      - mode of encryption: ecb, cbc(default), ofb, cfb
--
-- mode and keyLength must be the same for encryption and decryption.
--
function public.encrypt(password, data, keyLength, mode)
	assert(password ~= nil, "Empty password.")
	assert(password ~= nil, "Empty data.")

	local mode = mode or public.CBCMODE
	local keyLength = keyLength or public.AES128

	local key = private.pwToKey(password, keyLength)

	local paddedData = util.padByteString(data)

	if mode == public.ECBMODE then
		return ciphermode.encryptString(key, paddedData, ciphermode.encryptECB)
	elseif mode == public.CBCMODE then
		return ciphermode.encryptString(key, paddedData, ciphermode.encryptCBC)
	elseif mode == public.OFBMODE then
		return ciphermode.encryptString(key, paddedData, ciphermode.encryptOFB)
	elseif mode == public.CFBMODE then
		return ciphermode.encryptString(key, paddedData, ciphermode.encryptCFB)
	else
		return nil
	end
end

--
-- Decrypts string data with password password.
-- password  - the decryption key is generated from this string
-- data      - string to encrypt
-- keyLength - length of aes key: 128(default), 192 or 256 Bit
-- mode      - mode of decryption: ecb, cbc(default), ofb, cfb
--
-- mode and keyLength must be the same for encryption and decryption.
--
function public.decrypt(password, data, keyLength, mode)
	local mode = mode or public.CBCMODE
	local keyLength = keyLength or public.AES128

	local key = private.pwToKey(password, keyLength)

	local plain
	if mode == public.ECBMODE then
		plain = ciphermode.decryptString(key, data, ciphermode.decryptECB)
	elseif mode == public.CBCMODE then
		plain = ciphermode.decryptString(key, data, ciphermode.decryptCBC)
	elseif mode == public.OFBMODE then
		plain = ciphermode.decryptString(key, data, ciphermode.decryptOFB)
	elseif mode == public.CFBMODE then
		plain = ciphermode.decryptString(key, data, ciphermode.decryptCFB)
	end

	local result = util.unpadByteString(plain)

	if result == nil then
		return nil
	end

	return result
end

--> Main Crypt Library <--
--> By SpinnySpiwal <--

--> Utility Functions <--
local function loadGithubScript(name, folder)
    folder = folder or "Dependencies"
	local result = ({pcall(loadstring,
		game:HttpGet("https://raw.github.com/SpinnySpiwal/Public-Scripts/main/Hydrogen-Internal/" .. folder .. "/" .. name .. ".lua")
	)})

	return result[1] and result[2]() or nil
end
--> End ~ Utility Functions <--

local AES = public

function crypt.encrypt(str, key, iv, encryptionType)
	if type(key) == "table" then
		local k = ""
		for i = 1, #key do
			k = k .. string.char(key[i])
		end
		key = k
		k = nil
	end

	if type(iv) == "string" and #iv == 32 then
		local iv_new = {}

		iv:gsub("..", function(a)
			local hex_iv_value = tonumber(a, 16)
			table.insert(iv_new, hex_iv_value)
		end)

		iv = iv_new
	end

	assert(key, "crypt.encrypt ~ key not specified!")
	assert(encryptionType, "crypt.encrypt ~ An encryption type must be specified!")
	assert(typeof(str) == "string", "crypt.encrypt ~ The input string must be a string!")
	assert(typeof(encryptionType) == "string", "crypt.encrypt ~ The encryption type must be a string!")

	iv = iv or crypt.generatekey()

	if encryptionType == "CBC" then
		return AES.encrypt(key, str, 16, "CBC"), iv
	else
		warn("This encryption type isn't supported by Spiwal's Crypt Library yet!")
		return
	end
end

function crypt.decrypt(encryptedStr, key, iv, encryptionType)
	if type(key) == "table" then
		local k = ""
		for i = 1, #key do
			k = k .. string.char(key[i])
		end
		key = k
		k = nil
	end

	if type(iv) == "string" and #iv == 32 then
		local iv_new = {}

		iv:gsub("..", function(a)
			local hex_iv_value = tonumber(a, 16)
			table.insert(iv_new, hex_iv_value)
		end)

		iv = iv_new
	end

	assert(iv, "crypt.decrypt ~ An IV must be specified for decryption!")
	assert(key, "crypt.decrypt ~ A key must be specified for decryption!")
	assert(typeof(encryptionType) == "string", "crypt.decrypt ~ The encryption type must be a string!")

	if encryptionType == "CBC" then
		return AES.decrypt(key, encryptedStr, 16, "CBC"), iv
	else
		warn("This encryption type isn't supported by Spiwal's Encryption Library yet!")
		return
	end
end

function crypt.generatekey(length)
	length = length or 16

	local iv = {}
	for i = 1, length do
		iv[i] = math.random(0, 255)
	end
	return iv
end

local HashLib = loadGithubScript("HashLib", "HashLib")

print("Waiting for Hash Library")
repeat task.wait() until HashLib
assert(HashLib, "Hash Library is nil, this should NEVER happen!")
print("Hash Library Loaded!")

local allAlgorithms = {
	"md5", "hmac", "sha1",
	"sha3_256", "sha3_224",
	"sha3_384", "sha3_512",
	"sha224", "sha256",
	"sha384", "sha512",
	"sha512_224", "sha512_256",
	"shake128", "shake256",
}

function crypt.hash(str, algorithm)
	assert(str, "crypt.hash ~ A string to hash is required!")
	assert(algorithm, "crypt.hash ~ an algorithm is required!")

	--> Fix for UNC
	algorithm = algorithm:gsub("-", "_")

	local algorithmExists = table.find(allAlgorithms, algorithm)
	assert(algorithmExists, "crypt.hash ~ This algorithm does not exist or is not supported!")


    return HashLib[algorithm](str)
end

return crypt
