from typing import Any
import os
import json
import time
import argparse
import socket
import hashlib
import classes

def SendData(Socket: socket.socket, Data: str) -> None:
    data = []

    while (len(Data) >= 8192):
        data.append(Data[:8192])
        Data = Data[8192:]
    
    for d in data:
        Socket.send(d.encode("utf-8"))

    Socket.send("--END--".encode("utf-8"))

def RecvData(Socket: socket.socket) -> str:
    recvData = ""

    while (True):
        recv = Socket.recv(8192).decode("utf-8").strip()

        if (len(recv) == 0):
            return ""

        recvData += recv[:recv.rfind("--END--")] if (recv.endswith("--END--")) else recv

        if (recv.endswith("--END--")):
            break
    
    return recvData.strip()

def ClientReceive(Socket: socket.socket, Address: tuple[str, int], Data: str, Player: classes.Player) -> None:
    global LoggedPlayers

    if (len(Data) == 0):
        raise ValueError("No data. Probably connection closed.")

    try:
        parserdData: dict[str, Any] = json.loads(Data)
        action: str = parsedData["action"]
        arguments: list[Any] = parsedData["args"]
        result_code: str = "OK"
        result_args: list[Any] = []

        if (Player in LoggedPlayers and LoggedPlayers[Player] != Socket):
            result_args.append("Multiple instances are not allowed.")  # Make sure there are only one instance of a player
        elif (actio == "is_authorized"):
            result_args.append(Player in LoggedPlayers)
        elif (action == "connect"):
            time.sleep(0.1)

            username = arguments[0]
            passwdHash = hashlib.sha3_512(arguments[1].encode("utf-8")).hexdigest()
            playerFound = False

            for player in INFO["players"]:
                if (player.Username == username):
                    playerFound = True

                    if (player.AuthHash == passwdHash):
                        Player = classes.Player.FromDict(player)
                        LoggedPlayers.append(Player)

                    break

            if (Player not in LoggedPlayers and playerFound):
                result_code = "FAILED"
                result_args.append("Incorrect credentials.")
            else:
                INFO["players"] = Player
                LoggedPlayers.append(Player)
        elif (Player not in LoggedPlayers):
            pass  # Make sure the player exists
        elif (action == "set_pos"):
            x, y, z = arguments[0], arguments[1], arguments[2]
            Player.Position = (x, y, z)
        elif (action == "set_rot"):
            x, y, z = arguments[0], arguments[1], arguments[2]
            Player.Rotation = (x, y, z)
        elif (action == "set_scl"):
            x, y, z = arguments[0], arguments[1], arguments[2]
            Player.Scale = (x, y, z)
        elif (action == "set_lvl"):
            Player.CurrentLevel = arguments[0]
        else:
            state = "NOT FOUND"

        Socket.send(json.dumps({"code": result_code, "args": result_args}))
    except:
        pass

def ClientConnected(Socket: socket.socket, Address: tuple[str, int]) -> None:
    global PlayersCount, LoggesPlayers
    PlayersCount += 1
    player = classes.Player(PlayersCount)

    try:
        while (True):
            try:
                data = RecvData(Socket)
                ClientReceive(Socket, Address, data, player)
            except:
                break
    finally:
        if (player in LoggedPlayers):
            LoggesPlayers.pop(player)

        Socket.close()

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

PlayersCount: int = 0
LoggedPlayers: dict[classes.Player, socket.socket] = {}

if (__name__ == "__main__"):
    Server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    Server.bind((CONFIG["server"]["host"], CONFIG["server"]["port"]))
    Server.listen()

    print(f"Server started at '{CONFIG['server']['host']}:{CONFIG['server']['port']}'.", flush = True)

    while (True):
        try:
            clientSocket, clientAddr = Server.accept()
            ClientConnected(clientSocket, clientAddr)
        except KeyboardInterrupt:
            break

    print("\nClosing server...", flush = True)

    Server.shutdown(socket.SHUT_RDWR)
    Server.close()

    print("Server closed.", flush = True)
