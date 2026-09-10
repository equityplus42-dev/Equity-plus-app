const nodemailer = require('nodemailer');
const logger = require('./logger');

function getTransporter() {
  const user = process.env.SMTP_USER;
  const pass = process.env.SMTP_PASS;
  const host = process.env.SMTP_HOST || 'smtp.gmail.com';
  const isGmail = host.includes('gmail.com') || (user && user.endsWith('@gmail.com'));

  if (isGmail) {
    return nodemailer.createTransport({
      service: 'gmail',
      auth: { user, pass },
    });
  }

  return nodemailer.createTransport({
    host,
    port: parseInt(process.env.SMTP_PORT || '587', 10),
    secure: process.env.SMTP_SECURE === 'true',
    auth: { user, pass },
  });
}

async function sendOtpEmail(email, otp) {
  const smtpUser = process.env.SMTP_USER;
  const isMockSmtp = !smtpUser || smtpUser === 'mock_user@ethereal.email' || smtpUser === 'your_email@gmail.com';
  let activeTransporter;

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
      activeTransporter = getTransporter();
    }
  } else {
    activeTransporter = getTransporter();
  }

  const mailOptions = {
    from: process.env.SMTP_FROM || '"Vridhi Network" <equityplus42@gmail.com>',
    to: email,
    subject: 'Your Password Reset OTP - Vridhi Network',
    text: `Your OTP for resetting password is: ${otp}. It is valid for 15 minutes.`,
    html: `
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #e0e0e0; border-radius: 8px;">
        <h2 style="color: #6200EE; text-align: center;">Vridhi Network Password Reset</h2>
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

  try {
    const info = await activeTransporter.sendMail(mailOptions);
    logger.info(`Password reset OTP sent to ${email}: MessageID=${info.messageId}`);
    
    console.log(`[OTP GENERATED] Sent OTP to ${email}: ${otp}`);
    
    if (isMockSmtp) {
      const previewUrl = nodemailer.getTestMessageUrl(info);
      logger.info(`Ethereal email preview URL: ${previewUrl}`);
      console.log(`[DEV EMAIL PREVIEW] ${previewUrl}`);
    }

    return info;
  } catch (smtpErr) {
    logger.error(`SMTP Email dispatch failed for ${email}: ${smtpErr.message}`);
    console.warn(`[SMTP FALLBACK] Could not send email due to SMTP auth error (${smtpErr.message}). Generated OTP for ${email}: ${otp}`);
    // Return graceful fallback so user password reset flow is not blocked by SMTP config issues
    return { fallback: true, otp, error: smtpErr.message };
  }
}

module.exports = {
  sendOtpEmail,
};
