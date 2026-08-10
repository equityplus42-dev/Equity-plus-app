const cloudinaryService = require('../src/services/cloudinary.service');
const { videoConfig } = require('../src/config/cloudinary');

async function testUpload() {
  console.log('Testing Dedicated Video Cloudinary Config:', videoConfig);

  // Small dummy buffer representing a video payload for testing configuration
  const dummyBuffer = Buffer.from('test video content');

  try {
    const result = await cloudinaryService.uploadVideo(dummyBuffer, 'test_videos');
    console.log('✅ Video Upload Successful!');
    console.log('URL:', result.url);
    console.log('Duration:', result.duration);
    if (result.url.includes('qv1eskbe')) {
      console.log('🎉 VERIFIED: Uploaded strictly to dedicated Cloudinary account (qv1eskbe)!');
    } else {
      console.error('❌ ERROR: URL did not contain qv1eskbe!');
    }
  } catch (err) {
    console.error('❌ Upload failed with error:', err.message);
  }
}

testUpload();
