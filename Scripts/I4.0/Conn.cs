using Godot;
using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using System.IO;
using Newtonsoft.Json;
using TAO71.I4_0;
using FileAccess = Godot.FileAccess;

public partial class Conn : Node
{
	private static Resource Globals = ResourceLoader.Load("res://Scripts/Globals.gd");
	private static ClientConfiguration? Config = null;
	private static ClientSocket? Socket = null;
	private static string ConfigPath;
	[Export] public Control ErrorContainer;

	private static async Task ConnectToServer(List<string> Models)
	{
		bool modelFound = false;

		if (Socket.IsConnected())
		{
			foreach (string model in await Socket.GetAvailableModels())
			{
				if (Models.Contains(model))
				{
					modelFound = true;
					break;
				}
			}
			
			if (modelFound)
			{
				return;
			}
		}

		foreach (string server in (string[])Globals.Get("Instance").AsGodotObject().Get("I4_Servers"))
		{
			try
			{
				GD.Print($"Connecting to {server}");

				string srv = server;
				int port = 8060;

				if (server.Contains(':'))
				{
					port = int.Parse(server.Substring(server.Find(':') + 1));
					srv = server.Substring(0, server.Find(':'));
				}

				try
				{
					await Socket.Connect(srv, port, true);
				}
				catch
				{
					await Socket.Connect(srv, port, false);
				}

				GD.Print($"Finding {Models}");

				foreach (string model in await Socket.GetAvailableModels())
				{
					if (Models.Contains(model))
					{
						modelFound = true;
						break;
					}
				}

				if (modelFound)
				{
					break;
				}
			}
			catch (Exception ex)
			{
				GD.PushWarning($"Could not connect to server {server}: {ex}");
				continue;
			}
		}

		if (!modelFound)
		{
			GD.PushError("Could not connect to server of find any of the models.");
		}
	}

	public override async void _Ready()
	{
		Globals.Call("CheckInstance");
		ConfigPath = (string)Globals.Call("ParsePath", "[$GAME_CONFIG_DIR]/I4.0_config.json");

		if (Config == null)
		{
			Config = FileAccess.FileExists(ConfigPath) ? ClientConfiguration.FromDict(JsonConvert.DeserializeObject<Dictionary<string, object?>>(File.ReadAllText(ConfigPath))) : new ClientConfiguration();
			File.WriteAllText(ConfigPath, JsonConvert.SerializeObject(Config.ToDict(false)));
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
