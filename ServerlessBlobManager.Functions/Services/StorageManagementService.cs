using Azure.Storage;
using Azure.Storage.Blobs;
using Microsoft.Extensions.Configuration;
using ServerlessBlobManager.Functions.Interfaces;

namespace ServerlessBlobManager.Functions.Services
{
    public class StorageManagementService : IPersistenceManagementService
    {
        private class Configuration
        {
            public void Load(IConfiguration configuration)
            {
                this.AccountName = configuration.GetValue<string>("StorageAccountName");
                this.SharedKey = configuration.GetValue<string>("StorageAccessKey");
            }

            public string? AccountName { get; private set; }
            public string? SharedKey { get; private set; }
        }

        private readonly IConfiguration configuration;
        private readonly Configuration configurationValues;

        public StorageManagementService(IConfiguration configuration)
        {
            this.configuration = configuration;
            configurationValues = new Configuration();
            configurationValues.Load(configuration);
        }


        public async Task<bool> UndeleteBlobAsync(string blobUrl)
        {
            var credential = new StorageSharedKeyCredential(configurationValues.AccountName,
                configurationValues.SharedKey);

            var blobClient = new BlobClient(new Uri(blobUrl), credential);
            var undeleteResponse = await blobClient.UndeleteAsync();

            return !undeleteResponse.IsError;

        }
    }
}
