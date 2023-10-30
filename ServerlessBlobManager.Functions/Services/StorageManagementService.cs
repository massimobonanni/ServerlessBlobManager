using Azure.Core;
using Azure.Identity;
using Azure.Storage;
using Azure.Storage.Blobs;
using Microsoft.Extensions.Configuration;
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
            var blobClient = CreateBlobClient(blobUrl);

            var undeleteResponse = await blobClient.UndeleteAsync();

            return !undeleteResponse.IsError;

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
