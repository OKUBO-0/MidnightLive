"""Execute the pure Lua rules with the same Lua DLL shipped by Uno Engine."""
import ctypes
import os
import pathlib
import sys

engine_dir = pathlib.Path(os.environ.get('UNO_ENGINE_DIR', str(pathlib.Path.home() / 'Downloads' / 'dx12-engine-v1.10.0')))
with os.add_dll_directory(str(engine_dir)):
    lua = ctypes.CDLL(str(engine_dir / 'lua.dll'))
lua.luaL_newstate.restype = ctypes.c_void_p
lua.luaL_requiref.argtypes = [ctypes.c_void_p, ctypes.c_char_p, ctypes.c_void_p, ctypes.c_int]
lua.lua_settop.argtypes = [ctypes.c_void_p, ctypes.c_int]
lua.luaL_loadfilex.argtypes = [ctypes.c_void_p, ctypes.c_char_p, ctypes.c_char_p]
lua.lua_pcallk.argtypes = [ctypes.c_void_p, ctypes.c_int, ctypes.c_int, ctypes.c_int, ctypes.c_longlong, ctypes.c_void_p]
lua.lua_tolstring.argtypes = [ctypes.c_void_p, ctypes.c_int, ctypes.POINTER(ctypes.c_size_t)]
lua.lua_tolstring.restype = ctypes.c_char_p
lua.lua_close.argtypes = [ctypes.c_void_p]
state = lua.luaL_newstate()
for module in ['base', 'math', 'string', 'table', 'io', 'package']:
    lua.luaL_requiref(state, b'_G' if module == 'base' else module.encode(),
                      ctypes.cast(getattr(lua, 'luaopen_' + module), ctypes.c_void_p), 1)
    lua.lua_settop(state, 0)
test_path = pathlib.Path(sys.argv[1] if len(sys.argv) > 1 else 'tests/midnight_core_test.lua')
code = lua.luaL_loadfilex(state, str(test_path).encode(), None)
if code == 0:
    code = lua.lua_pcallk(state, 0, -1, 0, 0, None)
if code:
    print(lua.lua_tolstring(state, -1, None).decode('utf-8'), file=sys.stderr)
lua.lua_close(state)
sys.exit(1 if code else 0)
