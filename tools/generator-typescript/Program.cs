using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;

class ScriptEntity
{
    public string Name;
    public string Documentation;
}

class ScriptMethod : ScriptEntity
{
    public readonly List<string> Parameters = new List<string>();
}

class ScriptProperty : ScriptEntity
{
    public string Type = "any";
}

class ScriptEvent : ScriptEntity
{
}

class ScriptModule : ScriptEntity
{
    public readonly List<ScriptEvent> Events = new List<ScriptEvent>();
    public readonly List<ScriptProperty> Properties = new List<ScriptProperty>();
    public readonly List<ScriptMethod> Methods = new List<ScriptMethod>();
}

class Program
{
    static readonly Dictionary<string, ScriptModule> Modules = new Dictionary<string, ScriptModule>();

    static ScriptModule GetModule(string name)
    {
        if (Modules.ContainsKey(name))
            return Modules[name];

        var module = new ScriptModule {Name = name};
        Modules[name] = module;
        return module;
    }

    static void Parse(string value)
    {
        var json = JsonConvert.DeserializeObject<JToken>(value);
        var comments = json.FindTokens("comment");
        ScriptModule module = null;

        foreach (var comment in comments)
        {
            var attributes = comment["attributes"] as JObject;
            if (attributes == null)
                continue;

            var brief = (comment["brief"] ?? "").ToString();
            var full = (comment["full"] ?? "").ToString();

            if (attributes.ContainsKey("scriptModule"))
            {
                var scriptModule = attributes["scriptModule"];
                var name = scriptModule.ToString();

                if (!name.Contains('/'))
                    name = "FuseJS/" + name;

                module = GetModule(name);
                module.Documentation = full;
            }

            if (attributes.ContainsKey("scriptMethod"))
            {
                var scriptMethod = attributes["scriptMethod"];
                var result = new ScriptMethod {Name = scriptMethod["name"].ToString(), Documentation = full};
                module.Methods.Add(result);

                foreach (var parameter in scriptMethod["parameters"])
                    result.Parameters.Add(parameter.ToString());
            }

            if (attributes.ContainsKey("scriptProperty"))
            {
                var scriptProperty = attributes["scriptProperty"];
                var result = new ScriptProperty {Name = scriptProperty.ToString(), Documentation = full};

                // Extract type and docs
                if (result.Name.StartsWith("("))
                {
                    var i = result.Name.IndexOf(')', 1);
                    result.Type = result.Name.Substring(1, i - 1);
                    var parts = result.Name.Substring(i + 1).Trim().Split(' ');
                    result.Name = parts[0];
                    result.Documentation = string.Join(" ", parts.Skip(1));
                }

                // Skip duplicates
                if (module.Properties.Any(p => p.Name == result.Name))
                    continue;

                module.Properties.Add(result);
            }

            if (attributes.ContainsKey("scriptEvent"))
            {
                var scriptEvent = attributes["scriptEvent"];
                var result = new ScriptEvent {Name = scriptEvent.ToString(), Documentation = brief};
                module.Events.Add(result);
            }
        }
    }

    // Should follow https://github.com/Microsoft/tsdoc
    static void WriteDocumentation(string comment, string indent = "")
    {
        if (string.IsNullOrEmpty(comment))
            return;

        Console.WriteLine(indent + "/**");

        foreach (var line in comment.Trim('*').Trim().Split(new[] {"\r\n", "\r", "\n"}, StringSplitOptions.None))
            if (!string.IsNullOrWhiteSpace(line))
                Console.WriteLine(indent + " * " + line.Replace("\t", "    "));
            else
                Console.WriteLine(indent + " *");

        Console.WriteLine(indent + " */");
    }

    static int Main(string[] args)
    {
        if (args.Length < 1)
        {
            Console.Error.WriteLine("Usage: generator-typescript <path-to-api-docs>");
            return 1;
        }

        foreach (var file in Directory.EnumerateFiles(args[0], "*.json", SearchOption.AllDirectories))
        {
            var value = File.ReadAllText(file);
            if (!value.Contains("\"scriptModule\":"))
                continue;

            Parse(value);
        }

        // We want LF newlines in our output.
        Console.Out.NewLine = "\n";

        foreach (var module in Modules.Values)
        {
            WriteDocumentation(module.Documentation);
            Console.WriteLine($"declare module \"{module.Name}\" {{");

            foreach (var property in module.Properties)
            {
                WriteDocumentation(property.Documentation, "    ");
                Console.WriteLine($"    const {property.Name}: {property.Type};");
                Console.WriteLine();
            }

            if (module.Events.Count > 0)
            {
                Console.Write("    type Event = ");

                var first = true;
                foreach (var e in module.Events)
                {
                    if (!first)
                    {
                        Console.WriteLine(" |");
                        Console.Write("                 ");
                    }

                    Console.Write($"\"{e.Name}\"");
                    first = false;
                }

                Console.WriteLine(";");
                Console.WriteLine();

                var comment = "Registers a function to be called when one of the following events occur.\n\n";

                foreach (var e in module.Events)
                    comment += $"* `\"{e.Name}\"` - {e.Documentation}\n";

                WriteDocumentation(comment, "    ");
                Console.WriteLine($"    function on(event: Event, callback: () => void): void;");
                Console.WriteLine();
            }

            foreach (var method in module.Methods)
            {
                WriteDocumentation(method.Documentation, "    ");
                Console.Write($"    function {method.Name}(");

                var first = true;
                foreach (var parameter in method.Parameters)
                {
                    if (string.IsNullOrEmpty(parameter))
                        continue;

                    if (!first)
                        Console.Write(", ");

                    Console.Write($"{parameter.Trim('[', ']')}: any");
                    first = false;
                }

                Console.WriteLine($"): any;");
                Console.WriteLine();
            }

            Console.WriteLine("}");
            Console.WriteLine();
        }

        return 0;
    }
}

// Taken from https://stackoverflow.com/questions/19645501/searching-for-a-specific-jtoken-by-name-in-a-jobject-hierarchy
public static class JsonExtensions
{
    public static List<JToken> FindTokens(this JToken containerToken, string name)
    {
        List<JToken> matches = new List<JToken>();
        FindTokens(containerToken, name, matches);
        return matches;
    }

    private static void FindTokens(JToken containerToken, string name, List<JToken> matches)
    {
        if (containerToken.Type == JTokenType.Object)
        {
            foreach (JProperty child in containerToken.Children<JProperty>())
            {
                if (child.Name == name)
                {
                    matches.Add(child.Value);
                }
                FindTokens(child.Value, name, matches);
            }
        }
        else if (containerToken.Type == JTokenType.Array)
        {
            foreach (JToken child in containerToken.Children())
            {
                FindTokens(child, name, matches);
            }
        }
    }
}
