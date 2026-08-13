// Default URL for triggering event grid function in the local environment.
// http://localhost:7071/runtime/webhooks/EventGrid?functionName={functionname}
// https://learn.microsoft.com/en-us/azure/communication-services/how-tos/event-grid/local-testing-event-grid

using System.Text.Json;
using Azure.Messaging.EventGrid;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using ServerlessBlobManager.Functions.Entities;
using ServerlessBlobManager.Functions.Interfaces;

namespace ServerlessBlobManagement.Functions
{
    public class BlobDeletedFunction
    {
        private readonly ILogger<BlobDeletedFunction> _logger;
        private readonly IConfiguration configuration;
        private readonly IPersistenceManagementService persistentManagementService;
        
        public BlobDeletedFunction(IConfiguration configuration,
            IPersistenceManagementService persistentManagementService,
            ILogger<BlobDeletedFunction> logger)
        {
            _logger = logger;
            this.configuration = configuration;
            this.persistentManagementService = persistentManagementService;
        }

        [Function(nameof(BlobDeletedFunction))]
        public async Task Run([EventGridTrigger] EventGridEvent @event)
        {
            _logger.LogInformation("Event type: {type}, Event subject: {subject}", @event.EventType , @event.Subject);

            var data = @event.Data.ToObjectFromJson<BlobDeletedData>(new JsonSerializerOptions()
            {
                PropertyNameCaseInsensitive = true
            });

            var result = await this.persistentManagementService.UndeleteBlobAsync(data.url);

            _logger.LogInformation($"UndeleteBlobAsync {data.url} with {result} result");
        }
    }
}
