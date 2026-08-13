require('dotenv').config();
const {
  S3Client,
  ListObjectsV2Command,
  DeleteObjectsCommand,
  ListMultipartUploadsCommand,
  AbortMultipartUploadCommand,
} = require('@aws-sdk/client-s3');

const accountId = process.env.CLOUDFLARE_R2_ACCOUNT_ID;
const accessKeyId = process.env.CLOUDFLARE_R2_ACCESS_KEY_ID;
const secretAccessKey = process.env.CLOUDFLARE_R2_SECRET_ACCESS_KEY;
const bucketName = process.env.CLOUDFLARE_R2_BUCKET_NAME || 'vridhinetwork';

if (!accountId || !accessKeyId || !secretAccessKey || !bucketName) {
  console.error('❌ Error: Cloudflare R2 credentials missing in .env file!');
  process.exit(1);
}

const s3Client = new S3Client({
  region: 'auto',
  endpoint: `https://${accountId}.r2.cloudflarestorage.com`,
  forcePathStyle: true,
  credentials: {
    accessKeyId,
    secretAccessKey,
  },
});

async function clearR2BucketAndAborts() {
  console.log(`🔍 Connecting to Cloudflare R2 bucket "${bucketName}"...`);
  try {
    // 1. Delete all completed objects
    let isTruncated = true;
    let continuationToken;
    let totalDeleted = 0;

    while (isTruncated) {
      const listCommand = new ListObjectsV2Command({
        Bucket: bucketName,
        ContinuationToken: continuationToken,
      });

      const listResponse = await s3Client.send(listCommand);
      const objects = listResponse.Contents || [];

      if (objects.length > 0) {
        console.log(`📦 Found ${objects.length} file(s) to delete...`);

        const deleteParams = {
          Bucket: bucketName,
          Delete: {
            Objects: objects.map((obj) => ({ Key: obj.Key })),
            Quiet: false,
          },
        };

        const deleteCommand = new DeleteObjectsCommand(deleteParams);
        const deleteResponse = await s3Client.send(deleteCommand);

        const deletedCount = deleteResponse.Deleted ? deleteResponse.Deleted.length : 0;
        totalDeleted += deletedCount;

        deleteResponse.Deleted?.forEach((del) => {
          console.log(`  🗑️ Deleted: ${del.Key}`);
        });

        if (deleteResponse.Errors && deleteResponse.Errors.length > 0) {
          deleteResponse.Errors.forEach((err) => {
            console.error(`  ❌ Failed to delete ${err.Key}: ${err.Message}`);
          });
        }
      }

      isTruncated = listResponse.IsTruncated || false;
      continuationToken = listResponse.NextContinuationToken;
    }

    if (totalDeleted === 0) {
      console.log('ℹ️ No completed files found in bucket.');
    } else {
      console.log(`✅ Deleted ${totalDeleted} completed file(s).`);
    }

    // 2. Abort all pending / interrupted multi-part uploads
    console.log('\n🔍 Checking for pending/interrupted multi-part uploads...');
    const listMultipartCmd = new ListMultipartUploadsCommand({ Bucket: bucketName });
    const multipartRes = await s3Client.send(listMultipartCmd);
    const pendingUploads = multipartRes.Uploads || [];

    if (pendingUploads.length === 0) {
      console.log('✅ No pending or interrupted uploads found.');
    } else {
      console.log(`📦 Found ${pendingUploads.length} interrupted upload(s) to abort...`);
      for (const u of pendingUploads) {
        const abortCmd = new AbortMultipartUploadCommand({
          Bucket: bucketName,
          Key: u.Key,
          UploadId: u.UploadId,
        });
        await s3Client.send(abortCmd);
        console.log(`  ⏹️ Aborted pending upload: ${u.Key} (UploadId: ${u.UploadId})`);
      }
      console.log(`✅ Aborted all ${pendingUploads.length} interrupted multi-part upload(s).`);
    }

    console.log(`\n🎉 Cloudflare R2 bucket "${bucketName}" is completely clean!`);
  } catch (error) {
    console.error('❌ Error clearing R2 bucket:', error);
  }
}

clearR2BucketAndAborts();
