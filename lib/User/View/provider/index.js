const functions = require('firebase-functions');
const axios = require('axios');
const crypto = require('crypto');

exports.deleteCloudinaryImage = functions.https.onCall(async (data, context) => {
  // Ensure the user is authenticated
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated.');
  }

  const { publicId } = data;
  if (!publicId) {
    throw new functions.https.HttpsError('invalid-argument', 'Public ID is required.');
  }

  const cloudName = 'dlacr6mpw';
  const apiKey = '725816153519724';
  const apiSecret = '2XjX4826vpnX_PVkbLf7_bWNus4';
  const timestamp = Math.round(Date.now() / 1000).toString();

  // Generate signature
  const signatureString = `public_id=${publicId}&timestamp=${timestamp}${apiSecret}`;
  const signature = crypto.createHash('sha1').update(signatureString).digest('hex');

  try {
    const response = await axios.post(
      `https://api.cloudinary.com/v1_1/${cloudName}/image/destroy`,
      {
        public_id: publicId,
        timestamp: timestamp,
        api_key: apiKey,
        signature: signature,
      },
      {
        headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      }
    );

    if (response.data.result === 'ok') {
      return { success: true };
    } else {
      throw new functions.https.HttpsError('internal', `Failed to delete image: ${response.data.result}`);
    }
  } catch (error) {
    console.error('Error deleting image:', error);
    throw new functions.https.HttpsError('internal', `Error deleting image: ${error.message}`);
  }
});