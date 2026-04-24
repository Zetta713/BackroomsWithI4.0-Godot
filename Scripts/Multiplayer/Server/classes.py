from enum import Enum
from typing import Any, Self, Iterable
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

class BaseGameElement():
    __registry__ = {}

    def __init_subclass__(cls, **kwargs) -> None:
        super().__init_subclass__(**kwargs)
        cls.__registry__[cls.__name__] = cls

    def __init__(self) -> None:
        pass

    def GetDictionary_Save(self) -> dict[str, Any]:
        d = copy.deepcopy(self.__dict__)
        d["__type__"] = self.__class__.__name__

        for k, v in d.items():
            if (isinstance(v, list)):
                d[k] = [i.GetDictionary_Save() if (hasattr(i, "GetDictionary_Save")) else i for i in v]
            elif (hasattr(v, "GetDictionary_Save")):
                d[k] = v.GetDictionary_Save()

        return d

    def GetDictionary_Player(self) -> dict[str, Any]:
        d = copy.deepcopy(self.__dict__)

        for k, v in d.items():
            if (isinstance(v, list)):
                d[k] = [i.GetDictionary_Player() if (hasattr(i, "GetDictionary_Player")) else i for i in v]
            elif (hasattr(v, "GetDictionary_Player")):
                d[k] = v.GetDictionary_Player()

        return d

    @classmethod
    def FromDict(cls, D: dict[str, Any]) -> Self:
        targetCls = cls.__registry__.get(D.get("__type__", cls.__name__), cls)
        instance = targetCls.__new__(targetCls)

        for k, v in D.items():
            if (k == "__type__"):
                continue

            if (isinstance(v, list)):
                v = [BaseGameElement.FromDict(i) if (isinstance(i, dict) and "__type__" in i) else i for i in v]
            elif (isinstance(v, dict) and "__type__" in v):
                v = BaseGameElement.FromDict(v)
            
            setattr(instance, k, v)
        
        return instance

class ChatMessage(BaseGameElement):
    def __init__(self, Username: str, Content: list[dict[str, str]] | str) -> None:
        self.Username = Username

        if (isinstance(Content, list)):
            self.Content = Content
        else:
            self.Content = [{"type": "text", "text": str(self.Content)}]

class MapChunk(BaseGameElement):
    def __init__(self, Position: tuple[int, int, int]) -> None:
        super().__init__()

        self.Position: tuple[int, int, int] = Position
        self.DisabledIDs: list[str] = []  # Disabled items, entities, etc.

class Map(BaseGameElement):
    def __init__(self, Name: str, Seed: int = -1) -> None:
        super().__init__()

        self.Name = Name
        self.NoiseMaps: list[str] | None = None  # null = use the ones set in the game
        self.Seed: int = Seed if (Seed >= 0) else GetRandomID()
        self.ChunkData: list[MapChunk] = []

class GameEntity(BaseGameElement):
    def __init__(self, ID: int, IDPreffix: str = "GENT") -> None:
        super().__init__()

        self.IDPreffix: str = IDPreffix
        self.ID: int = ID
        self.Position: tuple[float, float, float] = (0, 0, 0)
        self.Rotation: tuple[float, float, float] = (0, 0, 0)
        self.Scale: tuple[float, float, float] = (1, 1, 1)
        self.Health: float = 100

    def GetID(self) -> str:
        return f"{self.IDPreffix}_{self.ID}"
    
    def GetDictionary_Save(self) -> dict[str, Any]:
        return super().GetDictionary_Save()

    def GetDictionary_Player(self) -> dict[str, Any]:
        return super().GetDictionary_Player()

class Item(GameEntity):
    def __init__(self, ID: int, Name: str) -> None:
        super().__init__(ID, "ITEM")

        self.Name: str = Name
        self.Tags: list[str] = []
        self.Seed: int = GetRandomID()
        self.OwnerID: str | None = None
        self.Permissions_Groups: Permission = Permission.INTERACT_MOVE
        self.Permissions_Everyone: Permission = Permission.NONE

class Player(GameEntity):
    def __init__(self, ID: int) -> None:
        super().__init__(ID, "PLAYER")

        # Identity
        self.Username: str = ""
        self.AuthHash: str | None = None

        # Data
        self.CurrentLevel: str = ""
        self.Tags: list[str] = []

        # Survival
        self.Water: float = 100
        self.Food: float = 100
        self.Stamina: float = 100

        # Groups
        self.Groups: list[str] = []

        # Items
        self.Items: list[str] = []
        self.ItemInHand: int | None = None  # Index of self.Items

        # Crouched
        self.Crouched: bool = False

        # Sounds
        self.Whistle: str | None = None

    def GetDictionary_Player(self) -> dict[str, Any]:
        d = super().GetDictionary_Player()
        d.pop("AuthHash")
        d.pop("Water")
        d.pop("Food")
        d.pop("Health")
        d.pop("ID")
        d.pop("IDPreffix")
        d.pop("Stamina")
        d.pop("Items")

        return d
    
    def GetDictionary_Save(self):
        d = super().GetDictionary_Save()
        d.pop("Whistling")

        return d

class Entity(GameEntity):
    def __init__(self, ID: int, Type: EntityType, Role: EntityRole) -> None:
        super().__init__(ID, "ENTITY")

        self.EntRole: EntityRole = Role
        self.EntType: EntityType = Type
        self.State: EntityState = EntityState.WANDERING
        self.TargetID: str | None = None