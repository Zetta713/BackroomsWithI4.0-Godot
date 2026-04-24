from typing import Any, Self
import copy
import classes

class BaseData():
    __registry__ = {}

    def __init_subclass__(cls, **kwargs) -> None:
        super().__init_subclass__(**kwargs)
        cls.__registry__[cls.__name__] = cls
    
    def ToDict(self) -> dict[str, Any]:
        d = copy.deepcopy(self.__dict__)
        d["__type__"] = self.__class__.__name__

        for k, v in d.items():
            if (isinstance(v, list)):
                d[k] = [i.ToDict() if (hasattr(i, "ToDict")) else i.GetDictionary_Save() if (hasattr(i, "GetDictionary_Save")) else i for i in v]
            elif (hasattr(v, "ToDict")):
                d[k] = v.ToDict()
            elif (hasattr(v, "GetDictionary_Save")):
                d[k] = v.GetDictionary_Save()

        return d
    
    @classmethod
    def FromDict(cls, D: dict[str, Any]) -> Self:
        targetCls = cls.__registry__.get(D.get("__type__", cls.__name__), cls)
        instance = targetCls.__new__(targetCls)

        for k, v in D.items():
            if (k == "__type__"):
                continue

            if (isinstance(v, list)):
                v = [BaseData.FromDict(i) if (isinstance(i, dict) and "__type__" in i) else i for i in v]
            elif (isinstance(v, dict) and "__type__" in v):
                v = BaseData.FromDict(v)
            
            setattr(instance, k, v)
        
        return instance

class Config(BaseData):
    def __init__(self) -> None:
        self.Server: dict[str, Any] = {"Host": "0.0.0.0", "Port": 65287, "MaxPlayers": 1000}
        self.PlayerAdminTag: str = "admin"

class Info(BaseData):
    def __init__(self) -> None:
        self.Worlds: list[classes.Map] = [
            classes.Map("Level 0", -1),
            classes.Map("Level 1", -1),
            classes.Map("Level 2", -1),
            classes.Map("Level 3", -1),
            classes.Map("Level 4", -1),
            classes.Map("Level 5", -1),
            classes.Map("Level 6", -1),
            classes.Map("Level 7", -1),
            classes.Map("Level 8", -1),
            classes.Map("Level 9", -1),
            classes.Map("Level The Hub", -1)
        ]
        self.Players: list[classes.Player] = []
        self.Objects: list[classes.Item] = []
        self.ChatMessages: list[classes.ChatMessage] = []