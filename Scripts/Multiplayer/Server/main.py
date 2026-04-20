from typing import Any
import os
import json
import time
import argparse
import threading
import asyncio
import websockets
import hashlib
import classes

import traceback

async def SendData(Socket: websockets.WebSocketServerProtocol, Data: str) -> None:
    data = Data
    chunks = []

    while (len(data) > 8192):
        chunks.append(data[:8192])
        data = data[8192:]

    chunks.append(data)
    
    for d in chunks:
        await Socket.send(d)

    #print("> --END--")
    await Socket.send("--END--")

async def RecvData(Socket: websockets.WebSocketServerProtocol) -> str:
    recvData = ""

    while (True):
        recv = await Socket.recv(decode = True)
        recv = recv.strip()

        #print(f"< {recv}")

        if (len(recv) == 0):
            return ""

        recvData += recv[:recv.rfind("--END--")] if (recv.endswith("--END--")) else recv

        if (recv.endswith("--END--")):
            break

    return recvData.strip()

async def ClientReceive(Socket: websockets.WebSocketServerProtocol, Data: str, Player: classes.Player) -> None:
    global LoggedPlayers

    if (len(Data) == 0):
        raise ValueError("No data. Probably connection closed.")

    try:
        parsedData: dict[str, Any] = json.loads(Data)
        action: str = parsedData["action"] if ("action" in parsedData) else ""
        arguments: list[Any] = parsedData["arguments"] if ("arguments" in parsedData) else []
        result_code: str = "OK"
        result_args: list[Any] = []

        if (action == "is_authorized"):
            result_args.append(Player in LoggedPlayers)
        elif (action == "connect" and Player not in LoggedPlayers):
            await asyncio.sleep(0.1)

            username = arguments[0]
            passwdHash = hashlib.sha3_512(arguments[1].encode("utf-8")).hexdigest()
            playerFound = False

            for player in INFO["players"]:
                if (player.Username == username):
                    playerFound = True

                    if (player.AuthHash == passwdHash):
                        Player = player
                        LoggedPlayers.append(Player)

                    break

            if (Player not in LoggedPlayers and playerFound):
                result_code = "FAILED"
                result_args.append("Incorrect credentials.")
            else:
                Player.Username = username
                Player.AuthHash = passwdHash

                INFO["players"].append(Player)
                LoggedPlayers.append(Player)
        elif (Player not in LoggedPlayers):
            result_args.append("Player is not logged in.")  # Make sure the player exists
        elif (action == "set_pos"):
            x, y, z = arguments[0], arguments[1], arguments[2]
            Player.Position = (x, y, z)
        elif (action == "set_rot"):
            x, y, z = arguments[0], arguments[1], arguments[2]
            Player.Rotation = (x, y, z)
        elif (action == "set_scl"):
            x, y, z = arguments[0], arguments[1], arguments[2]
            Player.Scale = (x, y, z)
        elif (action == "set_crouched"):
            Player.Crouched = arguments[0]
        elif (action == "set_lvl"):
            Player.CurrentLevel = arguments[0]
        elif (action == "get_lvls_data"):
            result_args.append([lvl.GetDictionary_Player() for lvl in INFO["worlds"]])
        elif (action == "get_all_players"):
            result_args.append([p.GetDictionary_Player() for p in LoggedPlayers])
        else:
            state = "NOT FOUND"

        await SendData(Socket, json.dumps({"code": result_code, "args": result_args}))
    except Exception as ex:
        await SendData(Socket, json.dumps({"code": "FAILED", "args": "Unknown error."}))
        #print(ex)
        traceback.print_exception(ex)

async def ClientConnected(Socket: websockets.WebSocketServerProtocol) -> None:
    global Clients, LoggedPlayers

    Clients.append(Socket)
    player = classes.Player(len(Clients))

    try:
        while (True):
            try:
                data = await RecvData(Socket)
                await ClientReceive(Socket, data, player)
            except:
                break
    finally:
        if (player in LoggedPlayers):
            LoggedPlayers.remove(player)

        Clients.remove(Socket)
        await Socket.close()

def EnsureFilesAndData() -> None:
    if (not os.path.exists(args.CONFIG_FILE)):
        with open(args.CONFIG_FILE, "x") as f:
            f.write(json.dumps(DEFAULT_CONFIG, indent = 4))

    if (not os.path.exists(args.INFO_FILE)):
        with open(args.INFO_FILE, "x") as f:
            f.write(json.dumps(DEFAULT_INFO, indent = 4))

def ReadConfig() -> dict[str, Any]:
    with open(args.CONFIG_FILE, "r") as f:
        conf = json.loads(f.read())

    for k, v in DEFAULT_CONFIG.items():
        if (k not in conf):
            conf[k] = v

    return conf

def ReadInfo() -> dict[str, Any]:
    with open(args.INFO_FILE, "r") as f:
        info = json.loads(f.read())

    for k, v in DEFAULT_INFO.items():
        if (k not in info):
            info[k] = v

    return info

async def __start_server__() -> None:
    global Server, ServerStarted

    Server = await websockets.serve(
        handler = ClientConnected,
        host = CONFIG["server"]["host"],
        port = CONFIG["server"]["port"],
        max_size = 8192,
        ssl = None
    )
    ServerStarted = True
    print(f"Server started at '{CONFIG['server']['host']}:{CONFIG['server']['port']}'.", flush = True)

    while (ServerStarted):
        await asyncio.sleep(0.1)

    await __stop_server__()

async def __stop_server__() -> None:
    global Server, Clients

    for client in Clients:
        await client.Close()

    Server.close(True)
    await Server.wait_closed()

DEFAULT_CONFIG_FILE: str = "./default_config.json"
DEFAULT_INFO_FILE: str = "./default_info.json"

with open(DEFAULT_CONFIG_FILE, "r") as f:
    DEFAULT_CONFIG: dict[str, Any] = json.loads(f.read())

with open(DEFAULT_INFO_FILE, "r") as f:
    DEFAULT_INFO: dict[str, Any] = json.loads(f.read())

parser = argparse.ArgumentParser(prog = "BWI Server", description = "Start a BWI server.")
parser.add_argument("--config", dest = "CONFIG_FILE", type = str, default = "./config.json", required = False, help = "Configuration file.")
parser.add_argument("--info", dest = "INFO_FILE", type = str, default = "./info.json", required = False, help = "Information file.")

args = parser.parse_args()

EnsureFilesAndData()
CONFIG = ReadConfig()
INFO = ReadInfo()

LoggedPlayers: list[classes.Player] = []
Clients: list[websockets.WebSocketServerProtocol] = []

if (__name__ == "__main__"):
    asyncio.set_event_loop(asyncio.new_event_loop())

    try:
        asyncio.get_event_loop().run_until_complete(__start_server__())
    except KeyboardInterrupt:
        pass
    finally:
        print("\nClosing server...", flush = True)
        ServerStarted = False

        print("Server closed.", flush = True)
