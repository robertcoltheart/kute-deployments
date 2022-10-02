using System;
using System.IO;
using System.Linq;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Runtime.InteropServices;
using System.Text.Json;
using System.Text.Json.Serialization;
using System.Threading.Tasks;
using static Bullseye.Targets;
using static SimpleExec.Command;

var client = new HttpClient();
client.DefaultRequestHeaders.UserAgent.Add(new ProductInfoHeaderValue("fluxcd", "1.0"));

Target("clean", () =>
{
    if (Directory.Exists("artifacts"))
    {
        Directory.Delete("artifacts", true);
    }
});

Target("restore", DependsOn("clean"), async () =>
{
    await DownloadRelease("mikefarah/yq");
    await DownloadRelease("yannh/kubeconform");
    await DownloadRelease("kubernetes-sigs/kustomize", false);
});

Target("yaml", DependsOn("restore"), () =>
{
    var files = Directory.GetFiles(".", "*.yaml", SearchOption.AllDirectories);

    foreach (var file in files)
    {
        Run(".tools/yq", $"e 'true' {file}");
    }
});

Target("clusters", DependsOn("restore"), () =>
{
    var files = Directory.GetFiles("clusters", "*.yaml", SearchOption.AllDirectories);

    foreach (var file in files)
    {
        Run(".tools/kubeconform", $"-strict -ignore-missing-schemas -schema-location default -schema-location /tmp/flux-crd-schemas -verbose {file}");
    }
});

Target("overlays", DependsOn("restore"), () =>
{
    var files = Directory.GetFiles(".", "kustomization.yaml", SearchOption.AllDirectories);

    foreach (var file in files)
    {
        Run(".tools/kustomize", $"build {Path.GetDirectoryName(file)} --load-restrictor=LoadRestrictionsNone > artifacts/output.yaml");
        Run(".tools/kubeconform", $"-strict -ignore-missing-schemas -schema-location default -schema-location /tmp/flux-crd-schemas -verbose artifacts/output.yaml");
    }
});

Target("build", DependsOn("yaml", "clusters", "overlays"), () =>
{
});

Target("default", DependsOn("build"));

await RunTargetsAndExitAsync(args);

async Task DownloadRelease(string repo, bool latest = true)
{
    var url = latest
        ? $"https://api.github.com/repos/{repo}/releases/latest"
        : $"https://api.github.com/repos/{repo}/releases";

    var osType = RuntimeInformation.IsOSPlatform(OSPlatform.Windows)
        ? "windows"
        : "linux";

    var release = await client.GetFromJsonAsync<Release>(url);
    var asset = release.Assets
        .Where(x => x.Name.Contains(osType))
        .Where(x => x.Name.Contains("amd64"))
        .FirstOrDefault(x => x.Name.EndsWith(".zip") || x.Name.EndsWith(".tar.gz"));

    if (asset != null)
    {
        var bytes = await client.GetByteArrayAsync(asset.BrowserDownloadUrl);
    }
}

class Release
{
    [JsonPropertyName("id")]
    public int Id { get; set; }

    [JsonPropertyName("name")]
    public string Name { get; set; }

    [JsonPropertyName("assets")]
    public Asset[] Assets { get; set; }
}

class Asset
{
    [JsonPropertyName("name")]
    public string Name { get; set; }

    [JsonPropertyName("browser_download_url")]
    public string BrowserDownloadUrl { get; set; }
}