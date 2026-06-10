using Godot;
using System;
using System.Collections.Generic;
using System.IO;
using System.Text.Json;
using TAO71.I4_0;
using FileAccess = Godot.FileAccess;

public partial class Conn : Node
{
	private static Resource Globals = ResourceLoader.Load("res://Scripts/Globals.gd");
	private static ClientConfiguration? Config = null;
	private static ClientSocket? Socket = null;
	private static string ConfigPath;

	public override void _Ready()
	{
		ConfigPath = (string)Globals.Call("ParsePath", "[$GAME_CONFIG_DIR]/I4.0_config.json");

		if (Config == null)
		{
			Config = FileAccess.FileExists(ConfigPath) ? ClientConfiguration.FromDict(JsonSerializer.Deserialize<Dictionary<string, object?>>(File.ReadAllText(ConfigPath))) : new ClientConfiguration();
			File.WriteAllText(ConfigPath, JsonSerializer.Serialize(Config.ToDict(false)));

			GD.Print(JsonSerializer.Serialize(Config.ToDict(false)));
		}

		if (Socket == null)
		{
			Socket = new ClientSocket("websocket", Config!);
		}
	}

	public override void _Process(double delta)
	{
	}
}
