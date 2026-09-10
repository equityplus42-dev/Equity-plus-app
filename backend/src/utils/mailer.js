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

  const formattedFrom = process.env.SMTP_FROM || '"Vridhi Network" <equityplus42@gmail.com>';
  const replyToAddress = process.env.SMTP_USER || 'equityplus42@gmail.com';

  const plainText = [
    'Vridhi Network - Password Reset Request',
    '',
    `Hello,`,
    '',
    'We received a request to reset the password for your Vridhi Network account.',
    `Your One-Time Password (OTP) is: ${otp}`,
    '',
    'This code is valid for 15 minutes. For your security, do not share this code with anyone.',
    '',
    'If you did not request a password reset, you can safely disregard this email. Your account remains secure.',
    '',
    '---',
    'Vridhi Network Security Team',
    'https://vridhi-network-app.vercel.app',
  ].join('\n');

  const htmlBody = `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <meta http-equiv="X-UA-Compatible" content="IE=edge">
  <title>Your Verification Code - Vridhi Network</title>
</head>
<body style="margin: 0; padding: 0; background-color: #f4f5f7; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; color: #172b4d; -webkit-font-smoothing: antialiased;">
  <table role="presentation" border="0" cellpadding="0" cellspacing="0" width="100%" style="background-color: #f4f5f7; padding: 30px 15px;">
    <tr>
      <td align="center">
        <table role="presentation" border="0" cellpadding="0" cellspacing="0" width="100%" style="max-width: 520px; background-color: #ffffff; border-radius: 12px; overflow: hidden; box-shadow: 0 4px 12px rgba(0, 0, 0, 0.05); border: 1px solid #e2e8f0;">
          <!-- Header -->
          <tr>
            <td style="background: linear-gradient(135deg, #4f46e5 0%, #7c3aed 100%); padding: 30px 24px; text-align: center;">
              <h1 style="margin: 0; font-size: 22px; font-weight: 700; color: #ffffff; letter-spacing: 0.5px;">Vridhi Network</h1>
              <p style="margin: 6px 0 0; font-size: 13px; color: #e0e7ff;">Account Security Verification</p>
            </td>
          </tr>
          <!-- Body Content -->
          <tr>
            <td style="padding: 32px 28px;">
              <p style="margin: 0 0 16px; font-size: 15px; line-height: 1.6; color: #334155;">Hello,</p>
              <p style="margin: 0 0 24px; font-size: 15px; line-height: 1.6; color: #334155;">
                We received a request to reset your password for your Vridhi Network account. Please use the following verification code to proceed:
              </p>
              
              <!-- OTP Box -->
              <div style="background-color: #f8fafc; border: 2px dashed #cbd5e1; border-radius: 10px; padding: 20px; text-align: center; margin: 24px 0;">
                <span style="font-family: 'Courier New', Courier, monospace; font-size: 36px; font-weight: 800; letter-spacing: 8px; color: #4f46e5; display: inline-block;">
                  ${otp}
                </span>
                <p style="margin: 8px 0 0; font-size: 12px; color: #64748b; text-transform: uppercase; letter-spacing: 1px;">
                  Valid for 15 minutes
                </p>
              </div>

              <p style="margin: 0 0 16px; font-size: 13px; line-height: 1.5; color: #64748b;">
                <strong>Security Notice:</strong> Never share this code with anyone. Vridhi Network support will never ask for your verification code.
              </p>
              <p style="margin: 0; font-size: 13px; line-height: 1.5; color: #64748b;">
                If you did not request this password reset, please ignore this email. Your password will remain unchanged.
              </p>
            </td>
          </tr>
          <!-- Footer -->
          <tr>
            <td style="background-color: #f8fafc; padding: 20px 28px; border-top: 1px solid #e2e8f0; text-align: center;">
              <p style="margin: 0 0 6px; font-size: 12px; color: #94a3b8;">
                &copy; ${new Date().getFullYear()} Vridhi Network. All rights reserved.
              </p>
              <p style="margin: 0; font-size: 11px; color: #94a3b8;">
                This is an automated security notification. Replies to this email address are not monitored.
              </p>
            </td>
          </tr>
        </table>
      </td>
    </tr>
  </table>
</body>
</html>`;

  const mailOptions = {
    from: formattedFrom,
    replyTo: replyToAddress,
    to: email,
    subject: `Your Vridhi Network Verification Code: ${otp}`,
    text: plainText,
    html: htmlBody,
    headers: {
      'X-Priority': '1',
      'X-MSMail-Priority': 'High',
      'Importance': 'high',
      'Auto-Submitted': 'auto-generated',
      'X-Auto-Response-Suppress': 'All',
    },
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
