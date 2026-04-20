from enum import Enum
from typing import Any, Self
import random
import copy

def GetRandomID() -> int:
    return random.randint(0, 2 ** 31 - 1)

class EntityRole(Enum):
    NEUTRAL = 0
    PASSIVE = 1
    AGGRESSIVE = 2

class EntityType(Enum):
    HOWLER = 0
    SMILER = 1
    WINDOWS = 2
    CLUMP_MALE = 3
    CLUMP_FEMALE = 4
    CLUMP_BABY = 5
    SKINSTEALER = 6
    I40 = 7

class EntityState(Enum):
    WANDERING = 0
    TRIGGERED = 1

class Permission(Enum):
    NONE = 0
    INTERACT = 1
    MOVE = 2
    INTERACT_MOVE = 3

class MapChunk():
    def __init__(self, Position: tuple[int, int, int]) -> None:
        self.Position: tuple[int, int, int] = Position
        self.DisabledIDs: list[str] = []  # Disabled items, entities, etc.

    def GetDictionary_Player(self) -> dict[str, Any]:
        return copy.deepcopy(self.__dict__)

class Map():
    def __init__(self, Name: str, Seed: int = -1) -> None:
        self.Name = Name
        self.NoiseMaps: list[str] | None = None  # null = use the ones set in the game
        self.Seed: int = Seed if (Seed >= 0) else GetRandomID()
        self.ChunkData: list[MapChunk] = []

    def GetDictionary_Player(self) -> dict[str, Any]:
        d = copy.deepcopy(self.__dict__)

        for k, v in d.items():
            if ("GetDictionary_Player" in v):
                d[k] = v.GetDictionary_Player()

        return d

class GameEntity():
    def __init__(self, ID: int, IDPreffix: str = "GENT") -> None:
        self.IDPreffix: str = IDPreffix
        self.ID: int = ID
        self.Position: tuple[float, float, float] = (0, 0, 0)
        self.Rotation: tuple[float, float, float] = (0, 0, 0)
        self.Scale: tuple[float, float, float] = (1, 1, 1)
        self.Health: float = 100

    def GetID(self) -> str:
        return f"{self.IDPreffix}_{self.ID}"
    
    def GetDictionary_Save(self) -> dict[str, Any]:
        return copy.deepcopy(self.__dict__)

    def GetDictionary_Player(self) -> dict[str, Any]:
        return self.GetDictionary_Save()

    @classmethod
    def FromDict(cls, D: dict[str, Any]) -> Self:
        instance = cls.__new__(cls)

        for k, v in D.items():
            setattr(instance, k, v)

        return instance

class Item(GameEntity):
    def __init__(self, ID: int, Name: str) -> None:
        super().__init__(ID, "ITEM")
        self.Name: str = Name
        self.Tags: list[str] = []
        self.Seed: int = GetRandomID()
        self.OwnerID: str | None = None
        self.Permissions_Groups: Permissions = Permissions.INTERACT_MOVE
        self.Permissions_Everyone: Permissions = Permissions.NONE

class Player(GameEntity):
    def __init__(self, ID: int) -> None:
        super().__init__(ID, "PLAYER")
        self.Username: str = ""
        self.AuthHash: str | None = None

        self.CurrentLevel: str = ""
        self.Tags: list[str] = []

        self.Water: float = 100
        self.Food: float = 100
        self.Stamina: float = 100

        self.Groups: list[str] = []

        self.Items: list[str] = []
        self.ItemInHand: int | None = None  # Index of self.Items

        self.Crouched: bool = False

    def GetDictionary_Player(self) -> dict[str, Any]:
        d = copy.deepcopy(self.__dict__)
        d.pop("AuthHash")
        d.pop("Water")
        d.pop("Food")
        d.pop("Health")
        d.pop("ID")
        d.pop("IDPreffix")
        d.pop("Stamina")
        d.pop("Items")

        return d

class Entity(GameEntity):
    def __init__(self, ID: int, Type: EntityType, Role: EntityRole) -> None:
        super().__init__(ID, "ENTITY")
        self.EntRole: EntityRole = Role
        self.EntType: EntityType = Type
        self.State: EntityState = EntityState.WANDERING
        self.TargetID: str | None = None
