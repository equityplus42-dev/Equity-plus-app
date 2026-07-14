const nodemailer = require('nodemailer');
const logger = require('./logger');

// Retrieve SMTP settings from env
const transporter = nodemailer.createTransport({
  host: process.env.SMTP_HOST || 'smtp.ethereal.email',
  port: parseInt(process.env.SMTP_PORT || '587'),
  secure: process.env.SMTP_SECURE === 'true',
  auth: {
    user: process.env.SMTP_USER || 'mock_user@ethereal.email',
    pass: process.env.SMTP_PASS || 'mock_pass',
  },
});

async function sendOtpEmail(email, otp) {
  let activeTransporter = transporter;
  
  const isMockSmtp = !process.env.SMTP_USER || process.env.SMTP_USER === 'your_email@gmail.com';
  if (isMockSmtp) {
    try {
      const testAccount = await nodemailer.createTestAccount();
      activeTransporter = nodemailer.createTransport({
        host: 'smtp.ethereal.email',
        port: 587,
        secure: false,
        auth: {
          user: testAccount.user,
          pass: testAccount.pass,
        },
      });
      logger.info(`Generated test Ethereal account: user=${testAccount.user}`);
    } catch (err) {
      logger.error('Failed to create Ethereal test account, will use fallback transporter', err);
    }
  }

  const mailOptions = {
    from: process.env.SMTP_FROM || '"Equilty Plus" <no-reply@equiltyplus.com>',
    to: email,
    subject: 'Your Password Reset OTP',
    text: `Your OTP for resetting password is: ${otp}. It is valid for 15 minutes.`,
    html: `
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #e0e0e0; border-radius: 8px;">
        <h2 style="color: #6200EE; text-align: center;">Equilty Plus Password Reset</h2>
        <p>Hello,</p>
        <p>You requested a password reset. Please use the following 4-digit One-Time Password (OTP) to complete the verification process:</p>
        <div style="background-color: #f3e5f5; padding: 15px; text-align: center; font-size: 24px; font-weight: bold; letter-spacing: 4px; color: #6200EE; margin: 20px 0; border-radius: 4px;">
          ${otp}
        </div>
        <p>This OTP is valid for 15 minutes. If you did not request this reset, please ignore this email.</p>
        <hr style="border: none; border-top: 1px solid #eeeeee; margin: 20px 0;" />
        <p style="font-size: 12px; color: #888888; text-align: center;">This is an automated system email. Please do not reply directly.</p>
      </div>
    `,
  };

  const info = await activeTransporter.sendMail(mailOptions);
  logger.info(`Password reset OTP sent to ${email}: MessageID=${info.messageId}`);
  
  // Log the OTP to the console/logger so it is easy to retrieve in development
  console.log(`[DEV OTP BYPASS] Sent OTP to ${email}: ${otp}`);
  
  if (isMockSmtp) {
    const previewUrl = nodemailer.getTestMessageUrl(info);
    logger.info(`Ethereal email preview URL: ${previewUrl}`);
    console.log(`[DEV EMAIL PREVIEW] ${previewUrl}`);
  }

  return info;
}

module.exports = {
  sendOtpEmail,
};
