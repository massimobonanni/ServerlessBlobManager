using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using ServerlessBlobManager.Functions.Interfaces;
using ServerlessBlobManager.Functions.Services;

var host = new HostBuilder()
    .ConfigureFunctionsWorkerDefaults()
    .ConfigureServices(s =>
    {
        s.AddSingleton<IPersistenceManagementService, StorageManagementService>();
    })
    .Build();

host.Run();
