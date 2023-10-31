using Azure.Core;
using Azure.Identity;
using Azure.Storage;
using Azure.Storage.Blobs;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using ServerlessBlobManager.Functions.Interfaces;
using System.Net.Security;

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
                this.UseManagedIdentity = configuration.GetValue<bool>("UseManagedIdentity");
            }

            public string? AccountName { get; private set; }
            public string? SharedKey { get; private set; }
            public bool UseManagedIdentity { get; set; }
        }

        private readonly ILogger<StorageManagementService> logger;
        private readonly IConfiguration configuration;
        private readonly Configuration configurationValues;

        public StorageManagementService(IConfiguration configuration, 
            ILoggerFactory loggerFactory)
        {
            this.logger = loggerFactory.CreateLogger<StorageManagementService>();
            this.configuration = configuration;
            configurationValues = new Configuration();
            configurationValues.Load(configuration);
        }


        public async Task<bool> UndeleteBlobAsync(string blobUrl)
        {
            this.logger.LogTrace($"Undeleteing blob {blobUrl}");
            
            var blobClient = CreateBlobClient(blobUrl);
            
            try
            {
                var undeleteResponse = await blobClient.UndeleteAsync();

                return !undeleteResponse.IsError;
            }
            catch (Exception ex)
            {
                this.logger.LogError(ex, $"Error undeleting blob {blobUrl}");
                return false;
            }

        }

        private BlobClient CreateBlobClient(string blobUrl)
        {
            BlobClient blobClient;
            if (this.configurationValues.UseManagedIdentity)
            {
                var credential = new ManagedIdentityCredential();
                blobClient = new BlobClient(new Uri(blobUrl), credential);
            }
            else
            {
                var credential = new StorageSharedKeyCredential(configurationValues.AccountName,
                    configurationValues.SharedKey);
                blobClient = new BlobClient(new Uri(blobUrl), credential);
            }
            return blobClient;
        }
    }
}
